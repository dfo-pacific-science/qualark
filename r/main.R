# Main R Script for Qualark Data Processing Pipeline
# Integrates Excel parsing and uses corrected data processing

library(here)
library(logging)

# Set up logging
basicConfig(level = 'INFO')
loginfo("Starting Qualark Data Processing Pipeline")

# Source all required modules
source(here("r", "config", "connections.R"))
source(here("r", "data_flows", "process_didson_data_corrected.R"))
source(here("r", "data_flows", "process_testfishing_data_corrected.R"))
source(here("r", "data_flows", "sql_integration.R"))
# SharePoint integration removed - using local storage instead
source(here("r", "utils", "email_notifications.R"))
source(here("r", "utils", "error_handling.R"))
source(here("r", "utils", "pipeline_status.R"))
source(here("r", "utils", "database_backup.R"))

# Function to parse Excel files to CSV with validation (Medallion Architecture)
parse_excel_files_with_validation <- function(excel_source_dir = "data/staging") {
  
  loginfo("Parsing Excel files to CSV with validation from staging folder (Bronze layer)")
  
  # Check if staging directory exists, create if not
  if (!dir.exists(excel_source_dir)) {
    loginfo(paste("Staging directory not found, creating:", excel_source_dir))
    dir.create(excel_source_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Check if there are files in staging, fallback to prototype_data if empty
  staging_files <- list.files(excel_source_dir, pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)
  if (length(staging_files) == 0) {
    loginfo("No Excel files found in staging folder, using prototype_data as fallback")
    excel_source_dir <- "prototype_data"
    if (!dir.exists(excel_source_dir)) {
      logerror(paste("Excel source directory not found:", excel_source_dir))
      return(list(status = "Error", message = "Excel source directory not found"))
    }
  }
  
  # Check if CSV files already exist and are recent (Bronze layer)
  csv_dir <- "data/bronze"
  if (dir.exists(csv_dir)) {
    csv_files <- list.files(csv_dir, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
    if (length(csv_files) > 0) {
      # Check if CSV files are newer than Excel files
      excel_files <- list.files(excel_source_dir, pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)
      if (length(excel_files) > 0) {
        excel_mtime <- max(file.mtime(excel_files))
        csv_mtime <- max(file.mtime(csv_files))
        
        if (csv_mtime > excel_mtime) {
          loginfo("Bronze layer CSV files are up to date, skipping Excel parsing")
          return(list(status = "Success", message = "Bronze layer CSV files are up to date"))
        }
      }
    }
  }
  
  # Parse Excel files
  tryCatch({
    source(here("r", "parse_excel_to_csv.R"))
    loginfo("Excel files parsed successfully")
    return(list(status = "Success", message = "Excel files parsed successfully"))
  }, error = function(e) {
    logerror(paste("Excel parsing failed:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to validate input data format
validate_input_format <- function() {
  
  loginfo("Validating input data format")
  
  validation_results <- list()
  
  # Check if required CSV files exist (Bronze layer)
  required_files <- c(
    "data/bronze/main_data/Qualark_2023_Test_Fishing_and_Sampling_Detailed_Catch_with_headers.csv",
    "data/bronze/lookup_data/DriftLocation_Sheet1_raw.csv",
    "data/bronze/lookup_data/Species_Species_raw.csv",
    "data/bronze/lookup_data/MeshSizes_MeshSizes_raw.csv"
  )
  
  for (file in required_files) {
    if (file.exists(file)) {
      validation_results[[basename(file)]] <- "Found"
    } else {
      validation_results[[basename(file)]] <- "Missing"
      logwarn(paste("Required file missing:", file))
    }
  }
  
  # Validate test fishing data structure
  testfishing_file <- required_files[1]
  if (file.exists(testfishing_file)) {
    tryCatch({
      data <- readr::read_csv(testfishing_file, show_col_types = FALSE)
      
      # Check for required columns
      required_columns <- c("Date", "Drift_Number", "Location", "Start_Time", "End_Time", "Duration", "Mesh_Size")
      missing_columns <- setdiff(required_columns, names(data))
      
      if (length(missing_columns) == 0) {
        validation_results$testfishing_structure <- "Valid"
        loginfo("Test fishing data structure is valid")
      } else {
        validation_results$testfishing_structure <- paste("Missing columns:", paste(missing_columns, collapse = ", "))
        logwarn(paste("Test fishing data missing columns:", paste(missing_columns, collapse = ", ")))
      }
      
    }, error = function(e) {
      validation_results$testfishing_structure <- paste("Error:", e$message)
      logerror(paste("Error validating test fishing data:", e$message))
    })
  }
  
  return(validation_results)
}

# Function to run test fishing pipeline using corrected processing
run_testfishing_pipeline_corrected <- function() {
  
  loginfo("Running Test Fishing pipeline with corrected processing")
  
  tryCatch({
    # Parse Excel files if needed
    parse_result <- parse_excel_files_with_validation()
    if (parse_result$status != "Success") {
      return(parse_result)
    }
    
    # Validate input format
    validation_results <- validate_input_format()
    if (any(grepl("Missing|Error", validation_results))) {
      logwarn("Input validation failed, but continuing with processing")
    }
    
    # Process test fishing data
    results <- process_all_testfishing_data()
    
    loginfo("Test Fishing pipeline completed successfully")
    return(list(
      status = "Success",
      message = "Test fishing data processed successfully",
      data = results,
      validation = validation_results
    ))
    
  }, error = function(e) {
    logerror(paste("Test Fishing pipeline failed:", e$message))
    return(list(
      status = "Error",
      message = e$message,
      data = NULL
    ))
  })
}

# Function to run DIDSON pipeline
run_didson_pipeline_corrected <- function() {
  
  loginfo("Running DIDSON pipeline with corrected processing")
  
  tryCatch({
    # Parse Excel files if needed
    parse_result <- parse_excel_files_with_validation()
    if (parse_result$status != "Success") {
      return(parse_result)
    }
    
    # Process DIDSON data
    results <- process_all_didson_data()
    
    loginfo("DIDSON pipeline completed successfully")
    return(list(
      status = "Success",
      message = "DIDSON data processed successfully",
      data = results
    ))
    
  }, error = function(e) {
    logerror(paste("DIDSON pipeline failed:", e$message))
    return(list(
      status = "Error",
      message = e$message,
      data = NULL
    ))
  })
}

# Main function to run all pipelines
run_all_pipelines <- function() {
  
  # Initialize pipeline status
  run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
  initialize_pipeline_status(run_id)
  
  loginfo("Starting all pipelines")
  
  results <- list()
  
  tryCatch({
    # Stage 1: Parse Excel files
    loginfo("Stage 1: Parsing Excel files")
    update_stage_status("Parse", "Running", "Parsing Excel files to CSV")
    
    parse_result <- parse_excel_files_with_validation()
    if (parse_result$status == "Success") {
      update_stage_status("Parse", "Success", "Excel files parsed successfully")
    } else {
      update_stage_status("Parse", "Failed", parse_result$message)
      add_error("Parse", parse_result$message)
    }
    
    # Stage 2: Process Test Fishing data
    loginfo("Stage 2: Processing Test Fishing data")
    update_stage_status("TestFishing", "Running", "Processing test fishing data")
    
    results$testfishing <- run_testfishing_pipeline_corrected()
    if (results$testfishing$status == "Success") {
      update_stage_status("TestFishing", "Success", "Test fishing data processed successfully")
    } else {
      update_stage_status("TestFishing", "Failed", results$testfishing$message)
      add_error("TestFishing", results$testfishing$message)
    }
    
    # Stage 3: Process DIDSON data
    loginfo("Stage 3: Processing DIDSON data")
    update_stage_status("DIDSON", "Running", "Processing DIDSON data")
    
    results$didson <- run_didson_pipeline_corrected()
    if (results$didson$status == "Success") {
      update_stage_status("DIDSON", "Success", "DIDSON data processed successfully")
    } else {
      update_stage_status("DIDSON", "Warning", results$didson$message)
      add_warning("DIDSON", results$didson$message)
    }
    
    # Stage 4: Database operations
    loginfo("Stage 4: Database operations")
    update_stage_status("Database", "Running", "Inserting data to database")
    
    # Populate lookup tables
    lookup_result <- populate_lookup_tables()
    if (lookup_result$status == "Success") {
      loginfo("Lookup tables populated successfully")
    } else {
      add_warning("Database", "Lookup table population failed")
    }
    
    # Insert processed data to database
    if (results$testfishing$status == "Success" && !is.null(results$testfishing$data)) {
      drifts_result <- insert_drifts_to_db(results$testfishing$data$drifts_data, run_id)
      fish_samples_result <- insert_fish_samples_to_db(results$testfishing$data$fish_samples_data, run_id)
      
      if (drifts_result$status == "Success" && fish_samples_result$status == "Success") {
        update_stage_status("Database", "Success", "Data inserted to database successfully")
      } else {
        update_stage_status("Database", "Warning", "Some database operations failed")
        add_warning("Database", "Database insertion had issues")
      }
    }
    
    # Stage 5: Data quality validation
    loginfo("Stage 5: Data quality validation")
    update_stage_status("Validation", "Running", "Validating data quality")
    
    validation_result <- validate_all_data()
    if (length(validation_result) > 0) {
      update_stage_status("Validation", "Success", "Data quality validation completed")
    } else {
      update_stage_status("Validation", "Warning", "No validation results generated")
    }
    
    # Stage 6: Create database backup
    loginfo("Stage 6: Creating database backup")
    update_stage_status("Backup", "Running", "Creating database backup")
    
    backup_result <- create_database_backup("full", run_id)
    if (backup_result$status == "Success") {
      update_stage_status("Backup", "Success", "Database backup created successfully")
    } else {
      update_stage_status("Backup", "Warning", backup_result$message)
      add_warning("Backup", backup_result$message)
    }
    
    # Stage 7: Send notifications
    loginfo("Stage 7: Sending notifications")
    update_stage_status("Notifications", "Running", "Sending notifications")
    
    # Send status notifications
    notification_result <- send_status_notifications()
    if (notification_result$status == "Success") {
      update_stage_status("Notifications", "Success", "Notifications sent successfully")
    } else {
      update_stage_status("Notifications", "Warning", notification_result$message)
      add_warning("Notifications", notification_result$message)
    }
    
    # Generate summary report
    generate_summary_report(results)
    
    # Create detailed status report
    status_report_path <- create_status_report()
    loginfo(paste("Status report created:", status_report_path))
    
    # Get final pipeline status
    final_status <- get_pipeline_summary()
    results$pipeline_status <- final_status
    
    loginfo("All pipelines completed successfully")
    
  }, error = function(e) {
    logerror(paste("Pipeline execution failed:", e$message))
    add_error("Pipeline", e$message)
    update_stage_status("Pipeline", "Failed", e$message)
  })
  
  return(results)
}

# Function to run specific pipeline
run_pipeline <- function(pipeline_type, input_path = NULL) {
  
  loginfo(paste("Running", pipeline_type, "pipeline"))
  
  if (pipeline_type == "didson") {
    result <- run_didson_pipeline_corrected()
  } else if (pipeline_type == "testfishing") {
    result <- run_testfishing_pipeline_corrected()
  } else if (pipeline_type == "parse") {
    # Just parse Excel files
    result <- parse_excel_files_with_validation()
  } else if (pipeline_type == "validate") {
    # Just validate input format
    result <- validate_input_format()
  } else if (pipeline_type == "data_quality") {
    # Just validate data quality
    result <- validate_all_data()
  } else {
    stop("Unknown pipeline type: ", pipeline_type)
  }
  
  return(result)
}

# Function to generate summary report
generate_summary_report <- function(results) {
  
  loginfo("Generating summary report")
  
  report_data <- list(
    timestamp = Sys.time(),
    total_pipelines = length(results),
    pipeline_results = results,
    summary = list(
      successful_runs = 0,
      failed_runs = 0
    )
  )
  
  # Count successful and failed runs
  for (pipeline_type in names(results)) {
    result <- results[[pipeline_type]]
    if (result$status == "Success" || result$status == "SuccessWithErrorFiles") {
      report_data$summary$successful_runs <- report_data$summary$successful_runs + 1
    } else {
      report_data$summary$failed_runs <- report_data$summary$failed_runs + 1
    }
  }
  
  # Save report
  report_path <- get_file_path("silver", "reports", 
                              paste0("pipeline_summary_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json"))
  
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)
  
  jsonlite::write_json(report_data, report_path, pretty = TRUE)
  
  loginfo(paste("Summary report saved to:", report_path))
  
  return(report_data)
}

# Function to validate data quality (simplified)
validate_all_data <- function() {
  
  loginfo("Validating data quality")
  
  # Validate silver layer data
  silver_files <- list.files(get_file_path("silver"), pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
  
  validation_results <- list()
  
  for (file in silver_files) {
    loginfo(paste("Validating file:", file))
    
    tryCatch({
      data <- readr::read_csv(file, show_col_types = FALSE)
      validation_results[[basename(file)]] <- list(
        status = "Pass",
        message = paste("File validated successfully with", nrow(data), "rows")
      )
    }, error = function(e) {
      validation_results[[basename(file)]] <<- list(
        status = "Fail",
        message = paste("Validation failed:", e$message)
      )
    })
  }
  
  # Save validation results
  validation_path <- get_file_path("silver", "validation", 
                                  paste0("validation_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json"))
  
  dir.create(dirname(validation_path), recursive = TRUE, showWarnings = FALSE)
  
  jsonlite::write_json(validation_results, validation_path, pretty = TRUE)
  
  loginfo(paste("Validation results saved to:", validation_path))
  
  return(validation_results)
}

# Command line interface
if (interactive()) {
  
  # Example usage
  cat("Qualark Data Processing Pipeline (Updated)\n")
  cat("==========================================\n\n")
  
  # Check if command line arguments are provided
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    # Run all pipelines
    cat("Running all pipelines...\n")
    results <- run_all_pipelines()
    
  } else if (args[1] == "didson") {
    # Run DIDSON pipeline
    cat("Running DIDSON pipeline...\n")
    result <- run_pipeline("didson")
    
  } else if (args[1] == "testfishing") {
    # Run Test Fishing pipeline
    cat("Running Test Fishing pipeline...\n")
    result <- run_pipeline("testfishing")
    
  } else if (args[1] == "parse") {
    # Parse Excel files only
    cat("Parsing Excel files to CSV...\n")
    result <- run_pipeline("parse")
    
  } else if (args[1] == "validate") {
    # Validate input format
    cat("Validating input data format...\n")
    result <- run_pipeline("validate")
    
  } else if (args[1] == "data_quality") {
    # Validate data quality
    cat("Validating data quality...\n")
    validation_results <- validate_all_data()
    
  } else {
    cat("Usage:\n")
    cat("  Rscript main.R                    # Run all pipelines\n")
    cat("  Rscript main.R didson             # Run DIDSON pipeline\n")
    cat("  Rscript main.R testfishing        # Run Test Fishing pipeline\n")
    cat("  Rscript main.R parse              # Parse Excel files to CSV\n")
    cat("  Rscript main.R validate           # Validate input data format\n")
    cat("  Rscript main.R data_quality       # Validate data quality\n")
  }
}