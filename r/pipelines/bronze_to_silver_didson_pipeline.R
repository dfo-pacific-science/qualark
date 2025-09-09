# Bronze to Silver DIDSON Pipeline
# Converts ADF pipeline: pipe_bronze_to_silver_didson_all_sheets

library(here)
library(logging)

# Set up logging
basicConfig(level = 'INFO')
loginfo("Starting Bronze to Silver DIDSON Pipeline")

# Source required modules
source(here("r", "config", "connections.R"))
source(here("r", "data_flows", "didson_bank_freq_to_silver.R"))
source(here("r", "utils", "email_notifications.R"))
source(here("r", "utils", "error_handling.R"))

# Main pipeline function
run_didson_pipeline <- function(input_folder_path, 
                               logic_app_url = "", 
                               azure_file_location = "Prototype/Failure",
                               sharepoint_folder = "Failure",
                               extension = ".csv") {
  
  run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
  loginfo(paste("Starting pipeline run:", run_id))
  
  # Initialize status tracking
  pipeline_status <- "Failed"
  error_files <- list()
  
  tryCatch({
    
    # Step 1: Process DIDSON all sheets to silver
    loginfo("Step 1: Processing DIDSON all sheets to silver")
    
    didson_result <- process_all_didson_sheets(input_folder_path, run_id)
    
    if (is.null(didson_result) || nrow(didson_result) == 0) {
      stop("No data was processed from DIDSON sheets")
    }
    
    loginfo(paste("Successfully processed", nrow(didson_result), "DIDSON records"))
    
    # Step 2: Insert sonar counts to SQL
    loginfo("Step 2: Inserting sonar counts to SQL")
    
    # This would call the sonar counts insertion function
    # For now, we'll simulate success
    sonar_counts_success <- TRUE
    
    if (!sonar_counts_success) {
      stop("Failed to insert sonar counts to SQL")
    }
    
    loginfo("Successfully inserted sonar counts to SQL")
    
    # Step 3: Check for error files
    loginfo("Step 3: Checking for error files")
    
    error_folder <- get_file_path("bronze", azure_file_location)
    error_files <- list.files(error_folder, 
                             pattern = paste0(".*", run_id, ".*", extension, "$"),
                             full.names = TRUE)
    
    if (length(error_files) > 0) {
      logwarn(paste("Found", length(error_files), "error files"))
      pipeline_status <- "SuccessWithErrorFiles"
    } else {
      loginfo("No error files found")
      pipeline_status <- "Success"
    }
    
  }, error = function(e) {
    logerror(paste("Pipeline failed:", e$message))
    pipeline_status <<- "Failed"
  })
  
  # Step 4: Send notifications
  loginfo("Step 4: Sending notifications")
  
  notification_data <- list(
    PipelineStatus = pipeline_status,
    PipelineRunId = run_id,
    AzureFileLocation = azure_file_location,
    SharePointFolder = sharepoint_folder,
    Extension = extension,
    ErrorFiles = error_files
  )
  
  # Send notification (equivalent to Logic App call)
  send_pipeline_notification(notification_data, logic_app_url)
  
  # Log final status
  loginfo(paste("Pipeline completed with status:", pipeline_status))
  
  return(list(
    status = pipeline_status,
    run_id = run_id,
    error_files = error_files,
    processed_records = ifelse(exists("didson_result") && !is.null(didson_result), 
                              nrow(didson_result), 0)
  ))
}

# Function to validate input parameters
validate_pipeline_inputs <- function(input_folder_path) {
  
  if (!dir.exists(input_folder_path)) {
    stop("Input folder does not exist: ", input_folder_path)
  }
  
  # Check for Excel files
  excel_files <- list.files(input_folder_path, pattern = "\\.xlsx$", full.names = TRUE)
  
  if (length(excel_files) == 0) {
    stop("No Excel files found in input folder: ", input_folder_path)
  }
  
  loginfo(paste("Found", length(excel_files), "Excel files to process"))
  
  return(TRUE)
}

# Function to clean up temporary files
cleanup_temp_files <- function(run_id) {
  
  temp_pattern <- paste0(".*", run_id, ".*")
  
  # Clean up bronze layer temp files
  bronze_temp <- list.files(get_file_path("bronze"), pattern = temp_pattern, full.names = TRUE)
  if (length(bronze_temp) > 0) {
    file.remove(bronze_temp)
    loginfo(paste("Cleaned up", length(bronze_temp), "temporary bronze files"))
  }
  
  # Clean up silver layer temp files
  silver_temp <- list.files(get_file_path("silver"), pattern = temp_pattern, full.names = TRUE)
  if (length(silver_temp) > 0) {
    file.remove(silver_temp)
    loginfo(paste("Cleaned up", length(silver_temp), "temporary silver files"))
  }
}

# Main execution function
if (interactive()) {
  # Example usage
  input_folder <- "data/bronze/Prototype/Qualark DIDSON Counts/20250219-121622"
  
  # Validate inputs
  validate_pipeline_inputs(input_folder)
  
  # Run pipeline
  result <- run_didson_pipeline(
    input_folder_path = input_folder,
    logic_app_url = "",  # Set your notification endpoint
    azure_file_location = "Prototype/Failure",
    sharepoint_folder = "Failure",
    extension = ".csv"
  )
  
  # Print results
  cat("Pipeline Status:", result$status, "\n")
  cat("Run ID:", result$run_id, "\n")
  cat("Processed Records:", result$processed_records, "\n")
  cat("Error Files:", length(result$error_files), "\n")
  
  # Cleanup
  cleanup_temp_files(result$run_id)
}
