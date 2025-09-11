# Pipeline Status Management for Qualark Pipeline
# Enhanced status tracking and management system

library(here)
library(logging)
library(jsonlite)

source(here("r", "utils", "email_notifications.R"))

# Global pipeline status tracking
PIPELINE_STATUS <- list(
  overall_status = "Not Started",
  start_time = NULL,
  end_time = NULL,
  run_id = "",
  stages = list(),
  errors = list(),
  warnings = list(),
  notifications_sent = FALSE
)

# Function to initialize pipeline status
initialize_pipeline_status <- function(run_id = "") {
  PIPELINE_STATUS <<- list(
    overall_status = "Running",
    start_time = Sys.time(),
    end_time = NULL,
    run_id = run_id,
    stages = list(),
    errors = list(),
    warnings = list(),
    notifications_sent = FALSE
  )
  
  loginfo(paste("Pipeline status initialized for run ID:", run_id))
}

# Function to update stage status
update_stage_status <- function(stage_name, status, message = "", details = NULL) {
  
  stage_info <- list(
    name = stage_name,
    status = status,
    message = message,
    details = details,
    timestamp = Sys.time(),
    duration = NA
  )
  
  # Calculate duration if this is a completion
  if (status %in% c("Success", "Failed", "Warning")) {
    if (stage_name %in% names(PIPELINE_STATUS$stages)) {
      start_time <- PIPELINE_STATUS$stages[[stage_name]]$timestamp
      stage_info$duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    }
  }
  
  PIPELINE_STATUS$stages[[stage_name]] <<- stage_info
  
  # Update overall status based on stage status
  update_overall_status()
  
  loginfo(paste("Stage", stage_name, "status updated to:", status))
}

# Function to update overall pipeline status
update_overall_status <- function() {
  
  if (length(PIPELINE_STATUS$stages) == 0) {
    PIPELINE_STATUS$overall_status <<- "Running"
    return()
  }
  
  # Get all stage statuses
  stage_statuses <- sapply(PIPELINE_STATUS$stages, function(x) x$status)
  
  # Determine overall status
  if (any(stage_statuses == "Failed")) {
    PIPELINE_STATUS$overall_status <<- "Failed"
  } else if (any(stage_statuses == "Warning")) {
    PIPELINE_STATUS$overall_status <<- "SuccessWithWarnings"
  } else if (all(stage_statuses %in% c("Success", "Skipped"))) {
    PIPELINE_STATUS$overall_status <<- "Success"
  } else {
    PIPELINE_STATUS$overall_status <<- "Running"
  }
  
  # Set end time if pipeline is complete
  if (PIPELINE_STATUS$overall_status %in% c("Success", "Failed", "SuccessWithWarnings")) {
    PIPELINE_STATUS$end_time <<- Sys.time()
  }
}

# Function to add error
add_error <- function(stage_name, error_message, error_details = NULL) {
  
  error_info <- list(
    stage = stage_name,
    message = error_message,
    details = error_details,
    timestamp = Sys.time()
  )
  
  PIPELINE_STATUS$errors <<- append(PIPELINE_STATUS$errors, list(error_info))
  
  logerror(paste("Error added for stage", stage_name, ":", error_message))
}

# Function to add warning
add_warning <- function(stage_name, warning_message, warning_details = NULL) {
  
  warning_info <- list(
    stage = stage_name,
    message = warning_message,
    details = warning_details,
    timestamp = Sys.time()
  )
  
  PIPELINE_STATUS$warnings <<- append(PIPELINE_STATUS$warnings, list(warning_info))
  
  logwarn(paste("Warning added for stage", stage_name, ":", warning_message))
}

# Function to get current pipeline status
get_pipeline_status <- function() {
  return(PIPELINE_STATUS)
}

# Function to get pipeline summary
get_pipeline_summary <- function() {
  
  # Calculate total duration
  total_duration <- NA
  if (!is.null(PIPELINE_STATUS$start_time)) {
    end_time <- PIPELINE_STATUS$end_time %||% Sys.time()
    total_duration <- as.numeric(difftime(end_time, PIPELINE_STATUS$start_time, units = "secs"))
  }
  
  # Count stages by status
  stage_statuses <- sapply(PIPELINE_STATUS$stages, function(x) x$status)
  # status_counts <- table(stage_statuses)  # Not used currently
  
  summary <- list(
    overall_status = PIPELINE_STATUS$overall_status,
    run_id = PIPELINE_STATUS$run_id,
    start_time = PIPELINE_STATUS$start_time,
    end_time = PIPELINE_STATUS$end_time,
    total_duration_seconds = total_duration,
    total_stages = length(PIPELINE_STATUS$stages),
    successful_stages = sum(stage_statuses == "Success", na.rm = TRUE),
    failed_stages = sum(stage_statuses == "Failed", na.rm = TRUE),
    warning_stages = sum(stage_statuses == "Warning", na.rm = TRUE),
    skipped_stages = sum(stage_statuses == "Skipped", na.rm = TRUE),
    total_errors = length(PIPELINE_STATUS$errors),
    total_warnings = length(PIPELINE_STATUS$warnings),
    notifications_sent = PIPELINE_STATUS$notifications_sent,
    stage_details = PIPELINE_STATUS$stages,
    errors = PIPELINE_STATUS$errors,
    warnings = PIPELINE_STATUS$warnings
  )
  
  return(summary)
}

# Function to save pipeline status to file
save_pipeline_status <- function(file_path = NULL) {
  
  if (is.null(file_path)) {
    file_path <- here("data", "silver", "reports", 
                     paste0("pipeline_status_", PIPELINE_STATUS$run_id, ".json"))
  }
  
  # Ensure directory exists
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  
  # Save status as JSON
  status_json <- toJSON(get_pipeline_summary(), pretty = TRUE, auto_unbox = TRUE)
  writeLines(status_json, file_path)
  
  loginfo(paste("Pipeline status saved to:", file_path))
  return(file_path)
}

# Function to send status notifications
send_status_notifications <- function() {
  
  if (PIPELINE_STATUS$notifications_sent) {
    loginfo("Notifications already sent for this pipeline run")
    return(list(status = "Skipped", message = "Notifications already sent"))
  }
  
  summary <- get_pipeline_summary()
  
  # Determine notification type based on status
  if (summary$overall_status == "Success") {
    result <- send_success_notification(
      paste("Pipeline completed successfully in", round(summary$total_duration_seconds, 2), "seconds"),
      details = list(
        paste("Successful stages:", summary$successful_stages),
        paste("Total stages:", summary$total_stages),
        paste("Run ID:", summary$run_id)
      ),
      run_id = summary$run_id
    )
  } else if (summary$overall_status == "Failed") {
    result <- send_error_notification(
      paste("Pipeline failed after", round(summary$total_duration_seconds, 2), "seconds"),
      details = summary$errors,
      run_id = summary$run_id
    )
  } else if (summary$overall_status == "SuccessWithWarnings") {
    result <- send_warning_notification(
      paste("Pipeline completed with warnings in", round(summary$total_duration_seconds, 2), "seconds"),
      details = summary$warnings,
      run_id = summary$run_id
    )
  } else {
    result <- send_pipeline_notification(
      summary$overall_status,
      paste("Pipeline status:", summary$overall_status),
      details = summary$stage_details,
      run_id = summary$run_id
    )
  }
  
  if (result$status == "Success") {
    PIPELINE_STATUS$notifications_sent <<- TRUE
    loginfo("Status notifications sent successfully")
  } else {
    logerror(paste("Failed to send status notifications:", result$message))
  }
  
  return(result)
}

# Function to create detailed status report
create_status_report <- function() {
  
  summary <- get_pipeline_summary()
  
  # Create HTML report
  html_content <- paste0(
    "<!DOCTYPE html>",
    "<html><head><style>",
    "body { font-family: Arial, sans-serif; margin: 20px; }",
    ".header { background-color: #0078d4; color: white; padding: 15px; border-radius: 5px; }",
    ".status-success { color: #28a745; }",
    ".status-failed { color: #dc3545; }",
    ".status-warning { color: #ffc107; }",
    ".status-running { color: #17a2b8; }",
    ".details { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }",
    "table { border-collapse: collapse; width: 100%; }",
    "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
    "th { background-color: #f2f2f2; }",
    "</style></head><body>",
    
    "<div class='header'>",
    "<h1>Qualark Pipeline Status Report</h1>",
    "<p><strong>Run ID:</strong> ", summary$run_id, "</p>",
    "<p><strong>Overall Status:</strong> <span class='status-", tolower(summary$overall_status), "'>", summary$overall_status, "</span></p>",
    "<p><strong>Start Time:</strong> ", summary$start_time, "</p>",
    "<p><strong>End Time:</strong> ", summary$end_time, "</p>",
    "<p><strong>Duration:</strong> ", round(summary$total_duration_seconds, 2), " seconds</p>",
    "</div>",
    
    "<div class='details'>",
    "<h2>Stage Summary</h2>",
    "<p>Successful: ", summary$successful_stages, " | Failed: ", summary$failed_stages, 
    " | Warnings: ", summary$warning_stages, " | Skipped: ", summary$skipped_stages, "</p>",
    "</div>",
    
    "<div class='details'>",
    "<h2>Stage Details</h2>",
    "<table><tr><th>Stage</th><th>Status</th><th>Message</th><th>Duration (s)</th></tr>"
  )
  
  # Add stage details
  for (stage_name in names(summary$stage_details)) {
    stage <- summary$stage_details[[stage_name]]
    duration_text <- ifelse(is.na(stage$duration), "N/A", round(stage$duration, 2))
    html_content <- paste0(html_content,
      "<tr><td>", stage_name, "</td>",
      "<td class='status-", tolower(stage$status), "'>", stage$status, "</td>",
      "<td>", stage$message, "</td>",
      "<td>", duration_text, "</td></tr>"
    )
  }
  
  html_content <- paste0(html_content, "</table></div>")
  
  # Add errors if any
  if (summary$total_errors > 0) {
    html_content <- paste0(html_content,
      "<div class='details'>",
      "<h2>Errors</h2><ul>"
    )
    for (error in summary$errors) {
      html_content <- paste0(html_content, "<li><strong>", error$stage, ":</strong> ", error$message, "</li>")
    }
    html_content <- paste0(html_content, "</ul></div>")
  }
  
  # Add warnings if any
  if (summary$total_warnings > 0) {
    html_content <- paste0(html_content,
      "<div class='details'>",
      "<h2>Warnings</h2><ul>"
    )
    for (warning in summary$warnings) {
      html_content <- paste0(html_content, "<li><strong>", warning$stage, ":</strong> ", warning$message, "</li>")
    }
    html_content <- paste0(html_content, "</ul></div>")
  }
  
  html_content <- paste0(html_content, "</body></html>")
  
  # Save HTML report
  report_path <- here("data", "silver", "reports", 
                     paste0("pipeline_status_report_", summary$run_id, ".html"))
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(html_content, report_path)
  
  loginfo(paste("Status report saved to:", report_path))
  return(report_path)
}

# Function to reset pipeline status
reset_pipeline_status <- function() {
  PIPELINE_STATUS <<- list(
    overall_status = "Not Started",
    start_time = NULL,
    end_time = NULL,
    run_id = "",
    stages = list(),
    errors = list(),
    warnings = list(),
    notifications_sent = FALSE
  )
  
  loginfo("Pipeline status reset")
}

# Test function
if (interactive()) {
  # Test pipeline status management
  initialize_pipeline_status("test-run-001")
  
  update_stage_status("Parse", "Success", "Excel files parsed successfully")
  update_stage_status("Process", "Success", "Data processed successfully")
  update_stage_status("Database", "Warning", "Some data validation warnings")
  
  summary <- get_pipeline_summary()
  print(summary)
  
  # Create status report
  report_path <- create_status_report()
  cat("Status report created:", report_path, "\n")
}
