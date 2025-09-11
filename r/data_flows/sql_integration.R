# SQL Database Integration for Qualark Pipeline
# Handles all database operations with flip switch for production use

library(DBI)
library(RPostgres)
library(dplyr)
library(here)
library(logging)

source(here("r", "config", "connections.R"))

# Global flag to enable/disable database operations
# Set to TRUE when ready for production database integration
ENABLE_DATABASE_OPERATIONS <- FALSE

# Function to check if database operations are enabled
is_database_enabled <- function() {
  return(ENABLE_DATABASE_OPERATIONS)
}

# Function to get database connection
get_database_connection <- function() {
  if (!is_database_enabled()) {
    loginfo("Database operations disabled - returning NULL connection")
    return(NULL)
  }
  
  tryCatch({
    conn <- get_db_connection()
    if (is.null(conn)) {
      logerror("Failed to establish database connection")
      return(NULL)
    }
    loginfo("Database connection established successfully")
    return(conn)
  }, error = function(e) {
    logerror(paste("Database connection error:", e$message))
    return(NULL)
  })
}

# Function to insert drifts data to database
insert_drifts_to_db <- function(drifts_data, run_id = "") {
  if (!is_database_enabled()) {
    loginfo("Database operations disabled - skipping drifts insertion")
    return(list(status = "Skipped", message = "Database operations disabled"))
  }
  
  conn <- get_database_connection()
  if (is.null(conn)) {
    return(list(status = "Error", message = "Database connection failed"))
  }
  
  tryCatch({
    # Prepare drifts data for database insertion
    db_drifts <- drifts_data %>%
      select(
        drift_date,
        drift_number,
        location_id,
        start_time = drift_start_time,
        end_time = drift_end_time,
        duration_minutes = duration,
        mesh_id = MeshId,
        comments,
        created_at = Sys.time(),
        updated_at = Sys.time(),
        updated_by = "qualark_pipeline"
      ) %>%
      mutate(
        # Convert time fields to proper format
        start_time = ifelse(is.na(start_time) || start_time == "", NA, 
                           paste0("1970-01-01 ", start_time)),
        end_time = ifelse(is.na(end_time) || end_time == "", NA, 
                         paste0("1970-01-01 ", end_time)),
        duration_minutes = ifelse(is.na(duration_minutes) || duration_minutes == "", NA, 
                                 paste0("1970-01-01 ", duration_minutes))
      )
    
    # Use upsert (INSERT ... ON CONFLICT ... DO UPDATE)
    # This matches the Azure ADF functionality
    upsert_query <- "
      INSERT INTO drifts (drift_date, drift_number, location_id, start_time, end_time, 
                         duration_minutes, mesh_id, comments, created_at, updated_at, updated_by)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (drift_date, drift_number) 
      DO UPDATE SET
        location_id = EXCLUDED.location_id,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time,
        duration_minutes = EXCLUDED.duration_minutes,
        mesh_id = EXCLUDED.mesh_id,
        comments = EXCLUDED.comments,
        updated_at = EXCLUDED.updated_at,
        updated_by = EXCLUDED.updated_by
    "
    
    # Insert data row by row for better error handling
    inserted_count <- 0
    for (i in seq_len(nrow(db_drifts))) {
      row <- db_drifts[i, ]
      dbExecute(conn, upsert_query, params = list(
        row$drift_date, row$drift_number, row$location_id, row$start_time, 
        row$end_time, row$duration_minutes, row$mesh_id, row$comments,
        row$created_at, row$updated_at, row$updated_by
      ))
      inserted_count <- inserted_count + 1
    }
    
    DBI::dbDisconnect(conn)
    
    loginfo(paste("Successfully inserted", inserted_count, "drift records to database"))
    return(list(status = "Success", message = paste("Inserted", inserted_count, "drift records")))
    
  }, error = function(e) {
    DBI::dbDisconnect(conn)
    logerror(paste("Error inserting drifts to database:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to insert fish samples data to database
insert_fish_samples_to_db <- function(fish_samples_data, run_id = "") {
  if (!is_database_enabled()) {
    loginfo("Database operations disabled - skipping fish samples insertion")
    return(list(status = "Skipped", message = "Database operations disabled"))
  }
  
  conn <- get_database_connection()
  if (is.null(conn)) {
    return(list(status = "Error", message = "Database connection failed"))
  }
  
  tryCatch({
    # Get drift IDs from database
    drift_lookup_query <- "
      SELECT drift_id, drift_date, drift_number 
      FROM drifts 
      WHERE drift_date = $1 AND drift_number = $2
    "
    
    # Prepare fish samples data for database insertion
    db_fish_samples <- fish_samples_data %>%
      mutate(
        created_at = Sys.time(),
        updated_at = Sys.time(),
        updated_by = "qualark_pipeline"
      )
    
    # Insert data row by row
    inserted_count <- 0
    for (i in seq_len(nrow(db_fish_samples))) {
      row <- db_fish_samples[i, ]
      
      # Get drift_id from database
      drift_result <- dbGetQuery(conn, drift_lookup_query, 
                                params = list(row$drift_date, row$drift_number))
      
      if (nrow(drift_result) > 0) {
        drift_id <- drift_result$drift_id[1]
        
        # Insert fish sample
        insert_query <- "
          INSERT INTO fish_samples (drift_id, species_id, retention_type, 
                                   life_history_type_id, catch_count, adipose_status, 
                                   created_at, updated_at, updated_by)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          ON CONFLICT (drift_id, species_id, life_history_type_id, adipose_status, retention_type)
          DO UPDATE SET
            catch_count = EXCLUDED.catch_count,
            updated_at = EXCLUDED.updated_at,
            updated_by = EXCLUDED.updated_by
        "
        
        dbExecute(conn, insert_query, params = list(
          drift_id, row$species_id, row$retention_type, row$life_history_type_id,
          row$catch_count, row$adipose_status, row$created_at, row$updated_at, row$updated_by
        ))
        inserted_count <- inserted_count + 1
      } else {
        logwarn(paste("No drift found for date:", row$drift_date, "number:", row$drift_number))
      }
    }
    
    DBI::dbDisconnect(conn)
    
    loginfo(paste("Successfully inserted", inserted_count, "fish sample records to database"))
    return(list(status = "Success", message = paste("Inserted", inserted_count, "fish sample records")))
    
  }, error = function(e) {
    DBI::dbDisconnect(conn)
    logerror(paste("Error inserting fish samples to database:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to insert sonar counts data to database
insert_sonar_counts_to_db <- function(sonar_counts_data, run_id = "") {
  if (!is_database_enabled()) {
    loginfo("Database operations disabled - skipping sonar counts insertion")
    return(list(status = "Skipped", message = "Database operations disabled"))
  }
  
  conn <- get_database_connection()
  if (is.null(conn)) {
    return(list(status = "Error", message = "Database connection failed"))
  }
  
  tryCatch({
    # Get sonar configuration IDs from database
    config_lookup_query <- "
      SELECT sonar_config_id, system, bank, frequency_setting 
      FROM sonar_configurations
    "
    config_data <- dbGetQuery(conn, config_lookup_query)
    
    # Prepare sonar counts data for database insertion
    db_sonar_counts <- sonar_counts_data %>%
      mutate(
        created_at = Sys.time(),
        updated_at = Sys.time(),
        updated_by = "qualark_pipeline"
      )
    
    # Match with sonar configurations
    matched_data <- db_sonar_counts %>%
      left_join(config_data, by = c("system", "bank", "frequency_setting"))
    
    # Insert data
    inserted_count <- 0
    for (i in seq_len(nrow(matched_data))) {
      row <- matched_data[i, ]
      
      if (!is.na(row$sonar_config_id)) {
        insert_query <- "
          INSERT INTO sonar_counts (sonar_config_id, date, count_hour, duration_minutes,
                                   up, down, net_up, salmon_per_hour, comments,
                                   created_at, updated_at, updated_by)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
          ON CONFLICT (sonar_config_id, date, count_hour)
          DO UPDATE SET
            duration_minutes = EXCLUDED.duration_minutes,
            up = EXCLUDED.up,
            down = EXCLUDED.down,
            net_up = EXCLUDED.net_up,
            salmon_per_hour = EXCLUDED.salmon_per_hour,
            comments = EXCLUDED.comments,
            updated_at = EXCLUDED.updated_at,
            updated_by = EXCLUDED.updated_by
        "
        
        dbExecute(conn, insert_query, params = list(
          row$sonar_config_id, row$date, row$count_hour, row$duration_minutes,
          row$up, row$down, row$net_up, row$salmon_per_hour, row$comments,
          row$created_at, row$updated_at, row$updated_by
        ))
        inserted_count <- inserted_count + 1
      } else {
        logwarn(paste("No sonar configuration found for system:", row$system, 
                     "bank:", row$bank, "frequency:", row$frequency_setting))
      }
    }
    
    DBI::dbDisconnect(conn)
    
    loginfo(paste("Successfully inserted", inserted_count, "sonar count records to database"))
    return(list(status = "Success", message = paste("Inserted", inserted_count, "sonar count records")))
    
  }, error = function(e) {
    DBI::dbDisconnect(conn)
    logerror(paste("Error inserting sonar counts to database:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to populate lookup tables from CSV files
populate_lookup_tables <- function() {
  if (!is_database_enabled()) {
    loginfo("Database operations disabled - skipping lookup table population")
    return(list(status = "Skipped", message = "Database operations disabled"))
  }
  
  conn <- get_database_connection()
  if (is.null(conn)) {
    return(list(status = "Error", message = "Database connection failed"))
  }
  
  tryCatch({
    # Load lookup data from CSV files
    lookup_files <- list(
      locations = "data/silver/lookups_from_csv/locations.csv",
      mesh_sizes = "data/silver/lookups_from_csv/mesh_sizes.csv",
      species = "data/silver/lookups_from_csv/species.csv",
      life_history_types = "data/silver/lookups_from_csv/life_history_types.csv",
      marked_fish_types = "data/silver/lookups_from_csv/marked_fish_types.csv",
      sonar_configurations = "data/silver/lookups_from_csv/sonar_configurations.csv"
    )
    
    results <- list()
    
    for (table_name in names(lookup_files)) {
      file_path <- lookup_files[[table_name]]
      if (file.exists(file_path)) {
        data <- readr::read_csv(file_path, show_col_types = FALSE)
        
        # Clear existing data and insert new data
        dbExecute(conn, paste("DELETE FROM", table_name))
        
        if (nrow(data) > 0) {
          dbWriteTable(conn, table_name, data, append = TRUE, row.names = FALSE)
          results[[table_name]] <- paste("Inserted", nrow(data), "records")
          loginfo(paste("Populated", table_name, "with", nrow(data), "records"))
        } else {
          results[[table_name]] <- "No data to insert"
        }
      } else {
        results[[table_name]] <- "File not found"
        logwarn(paste("Lookup file not found:", file_path))
      }
    }
    
    DBI::dbDisconnect(conn)
    
    return(list(status = "Success", message = "Lookup tables populated", details = results))
    
  }, error = function(e) {
    DBI::dbDisconnect(conn)
    logerror(paste("Error populating lookup tables:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to enable database operations (flip switch)
enable_database_operations <- function() {
  ENABLE_DATABASE_OPERATIONS <<- TRUE
  loginfo("Database operations ENABLED - all database functions will now execute")
}

# Function to disable database operations (flip switch)
disable_database_operations <- function() {
  ENABLE_DATABASE_OPERATIONS <<- FALSE
  loginfo("Database operations DISABLED - all database functions will be skipped")
}

# Function to check database status
get_database_status <- function() {
  if (!is_database_enabled()) {
    return(list(enabled = FALSE, message = "Database operations are disabled"))
  }
  
  conn <- get_database_connection()
  if (is.null(conn)) {
    return(list(enabled = TRUE, connected = FALSE, message = "Database operations enabled but connection failed"))
  }
  
  # Test query
  tryCatch({
    result <- dbGetQuery(conn, "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = 'public'")
    DBI::dbDisconnect(conn)
    return(list(enabled = TRUE, connected = TRUE, message = paste("Connected to database with", result$table_count, "tables")))
  }, error = function(e) {
    DBI::dbDisconnect(conn)
    return(list(enabled = TRUE, connected = FALSE, message = paste("Database connection test failed:", e$message)))
  })
}

# Test function
if (interactive()) {
  # Test database status
  status <- get_database_status()
  cat("Database Status:", status$message, "\n")
  
  # Test enabling/disabling
  disable_database_operations()
  cat("Database operations disabled\n")
  
  enable_database_operations()
  cat("Database operations enabled\n")
}
