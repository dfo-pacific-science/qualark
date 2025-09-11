# Database Backup Strategy for Qualark Pipeline
# Handles automated database backups and recovery procedures

library(here)
library(logging)
library(DBI)
library(RPostgres)

source(here("r", "config", "connections.R"))
source(here("r", "data_flows", "sql_integration.R"))

# Global flag to enable/disable backup operations
# Set to TRUE when ready for production backup integration
ENABLE_BACKUP_OPERATIONS <- FALSE

# Function to check if backup operations are enabled
is_backup_enabled <- function() {
  return(ENABLE_BACKUP_OPERATIONS)
}

# Function to create database backup
create_database_backup <- function(backup_type = "full", run_id = "") {
  
  if (!is_backup_enabled()) {
    loginfo("Backup operations disabled - skipping database backup")
    return(list(status = "Skipped", message = "Backup operations disabled"))
  }
  
  if (!is_database_enabled()) {
    logwarn("Database operations disabled - cannot create backup")
    return(list(status = "Error", message = "Database operations disabled"))
  }
  
  tryCatch({
    # Create backup filename with timestamp
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    backup_filename <- paste0("qualark_backup_", backup_type, "_", run_id, "_", timestamp, ".sql")
    
    # Create backup directory
    backup_dir <- here("data", "backups", "database")
    dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
    backup_path <- file.path(backup_dir, backup_filename)
    
    # Get database configuration
    db_config <- get_db_config()
    if (is.null(db_config)) {
      return(list(status = "Error", message = "Database configuration not available"))
    }
    
    # Create pg_dump command
    pg_dump_cmd <- paste0(
      "pg_dump",
      " -h ", db_config$server,
      " -p ", db_config$port,
      " -U ", db_config$username,
      " -d ", db_config$database,
      " --no-password",
      " --verbose",
      " --format=custom",
      " --compress=9",
      " --file=", backup_path
    )
    
    # Set password environment variable
    old_password <- Sys.getenv("PGPASSWORD")
    Sys.setenv(PGPASSWORD = db_config$password)
    
    # Execute backup command
    system(pg_dump_cmd, intern = TRUE)
    
    # Restore original password
    if (old_password == "") {
      Sys.unsetenv("PGPASSWORD")
    } else {
      Sys.setenv(PGPASSWORD = old_password)
    }
    
    # Check if backup was successful
    if (file.exists(backup_path) && file.size(backup_path) > 0) {
      loginfo(paste("Database backup created successfully:", backup_path))
      
      # Create backup metadata
      backup_metadata <- list(
        backup_type = backup_type,
        run_id = run_id,
        timestamp = timestamp,
        filename = backup_filename,
        file_path = backup_path,
        file_size = file.size(backup_path),
        database = db_config$database,
        created_by = "qualark_pipeline"
      )
      
      # Save metadata
      metadata_path <- paste0(backup_path, ".metadata.json")
      writeLines(jsonlite::toJSON(backup_metadata, pretty = TRUE), metadata_path)
      
      return(list(
        status = "Success",
        message = paste("Backup created successfully:", backup_filename),
        backup_path = backup_path,
        metadata = backup_metadata
      ))
    } else {
      return(list(status = "Error", message = "Backup file was not created or is empty"))
    }
    
  }, error = function(e) {
    logerror(paste("Error creating database backup:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to restore database from backup
restore_database_backup <- function(backup_path, run_id = "") {
  
  if (!is_backup_enabled()) {
    loginfo("Backup operations disabled - skipping database restore")
    return(list(status = "Skipped", message = "Backup operations disabled"))
  }
  
  if (!is_database_enabled()) {
    logwarn("Database operations disabled - cannot restore backup")
    return(list(status = "Error", message = "Database operations disabled"))
  }
  
  if (!file.exists(backup_path)) {
    return(list(status = "Error", message = "Backup file not found"))
  }
  
  tryCatch({
    # Get database configuration
    db_config <- get_db_config()
    if (is.null(db_config)) {
      return(list(status = "Error", message = "Database configuration not available"))
    }
    
    # Create pg_restore command
    pg_restore_cmd <- paste0(
      "pg_restore",
      " -h ", db_config$server,
      " -p ", db_config$port,
      " -U ", db_config$username,
      " -d ", db_config$database,
      " --no-password",
      " --verbose",
      " --clean",
      " --if-exists",
      " ", backup_path
    )
    
    # Set password environment variable
    old_password <- Sys.getenv("PGPASSWORD")
    Sys.setenv(PGPASSWORD = db_config$password)
    
    # Execute restore command
    system(pg_restore_cmd, intern = TRUE)
    
    # Restore original password
    if (old_password == "") {
      Sys.unsetenv("PGPASSWORD")
    } else {
      Sys.setenv(PGPASSWORD = old_password)
    }
    
    loginfo(paste("Database restored successfully from:", backup_path))
    
    return(list(
      status = "Success",
      message = paste("Database restored successfully from:", basename(backup_path)),
      backup_path = backup_path
    ))
    
  }, error = function(e) {
    logerror(paste("Error restoring database backup:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to list available backups
list_database_backups <- function() {
  
  backup_dir <- here("data", "backups", "database")
  
  if (!dir.exists(backup_dir)) {
    return(list(status = "Info", message = "No backup directory found", backups = list()))
  }
  
  # Find all backup files
  backup_files <- list.files(backup_dir, pattern = "\\.sql$", full.names = TRUE)
  
  if (length(backup_files) == 0) {
    return(list(status = "Info", message = "No backup files found", backups = list()))
  }
  
  # Get backup metadata
  backups <- list()
  for (backup_file in backup_files) {
    metadata_file <- paste0(backup_file, ".metadata.json")
    
    if (file.exists(metadata_file)) {
      metadata <- jsonlite::fromJSON(metadata_file)
      backups[[basename(backup_file)]] <- metadata
    } else {
      # Create basic metadata from file info
      file_info <- file.info(backup_file)
      backups[[basename(backup_file)]] <- list(
        filename = basename(backup_file),
        file_path = backup_file,
        file_size = file_info$size,
        created_time = file_info$mtime,
        backup_type = "unknown"
      )
    }
  }
  
  return(list(
    status = "Success",
    message = paste("Found", length(backups), "backup files"),
    backups = backups
  ))
}

# Function to clean up old backups
cleanup_old_backups <- function(retention_days = 30) {
  
  if (!is_backup_enabled()) {
    loginfo("Backup operations disabled - skipping backup cleanup")
    return(list(status = "Skipped", message = "Backup operations disabled"))
  }
  
  backup_dir <- here("data", "backups", "database")
  
  if (!dir.exists(backup_dir)) {
    return(list(status = "Info", message = "No backup directory found"))
  }
  
  tryCatch({
    # Find all backup files
    backup_files <- list.files(backup_dir, pattern = "\\.sql$", full.names = TRUE)
    
    if (length(backup_files) == 0) {
      return(list(status = "Info", message = "No backup files found"))
    }
    
    # Calculate cutoff date
    cutoff_date <- Sys.time() - (retention_days * 24 * 60 * 60)
    
    # Find old files
    old_files <- c()
    for (backup_file in backup_files) {
      file_time <- file.info(backup_file)$mtime
      if (file_time < cutoff_date) {
        old_files <- c(old_files, backup_file)
      }
    }
    
    if (length(old_files) == 0) {
      return(list(status = "Info", message = "No old backup files to clean up"))
    }
    
    # Delete old files and their metadata
    deleted_count <- 0
    for (old_file in old_files) {
      # Delete backup file
      if (file.remove(old_file)) {
        deleted_count <- deleted_count + 1
        
        # Delete metadata file if it exists
        metadata_file <- paste0(old_file, ".metadata.json")
        if (file.exists(metadata_file)) {
          file.remove(metadata_file)
        }
      }
    }
    
    loginfo(paste("Cleaned up", deleted_count, "old backup files"))
    
    return(list(
      status = "Success",
      message = paste("Cleaned up", deleted_count, "old backup files"),
      deleted_count = deleted_count
    ))
    
  }, error = function(e) {
    logerror(paste("Error cleaning up old backups:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to create backup schedule
create_backup_schedule <- function() {
  
  # This would typically integrate with cron or Windows Task Scheduler
  # For now, we'll create a simple schedule configuration
  
  schedule_config <- list(
    full_backup = list(
      frequency = "daily",
      time = "02:00",
      retention_days = 30
    ),
    incremental_backup = list(
      frequency = "hourly",
      time = "00:00",
      retention_days = 7
    ),
    weekly_backup = list(
      frequency = "weekly",
      day = "sunday",
      time = "03:00",
      retention_days = 90
    )
  )
  
  # Save schedule configuration
  schedule_path <- here("data", "backups", "schedule_config.json")
  dir.create(dirname(schedule_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(jsonlite::toJSON(schedule_config, pretty = TRUE), schedule_path)
  
  loginfo("Backup schedule configuration created")
  return(schedule_config)
}

# Function to enable backup operations (flip switch)
enable_backup_operations <- function() {
  ENABLE_BACKUP_OPERATIONS <<- TRUE
  loginfo("Backup operations ENABLED - all backup functions will now execute")
}

# Function to disable backup operations (flip switch)
disable_backup_operations <- function() {
  ENABLE_BACKUP_OPERATIONS <<- FALSE
  loginfo("Backup operations DISABLED - all backup functions will be skipped")
}

# Function to check backup status
get_backup_status <- function() {
  if (!is_backup_enabled()) {
    return(list(enabled = FALSE, message = "Backup operations are disabled"))
  }
  
  if (!is_database_enabled()) {
    return(list(enabled = TRUE, database_enabled = FALSE, message = "Backup operations enabled but database operations disabled"))
  }
  
  # Check backup directory
  backup_dir <- here("data", "backups", "database")
  if (!dir.exists(backup_dir)) {
    return(list(enabled = TRUE, database_enabled = TRUE, backup_dir_exists = FALSE, message = "Backup operations enabled but backup directory does not exist"))
  }
  
  # List available backups
  backup_list <- list_database_backups()
  
  return(list(
    enabled = TRUE,
    database_enabled = TRUE,
    backup_dir_exists = TRUE,
    message = paste("Backup operations enabled with", length(backup_list$backups), "available backups"),
    backup_count = length(backup_list$backups)
  ))
}

# Test function
if (interactive()) {
  # Test backup status
  status <- get_backup_status()
  cat("Backup Status:", status$message, "\n")
  
  # Test enabling/disabling
  disable_backup_operations()
  cat("Backup operations disabled\n")
  
  enable_backup_operations()
  cat("Backup operations enabled\n")
  
  # List available backups
  backups <- list_database_backups()
  cat("Available backups:", length(backups$backups), "\n")
}
