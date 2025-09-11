# Enhanced Email Notifications for Qualark Pipeline
# Handles sending notifications for pipeline status, errors, and comprehensive reporting

library(mailR)
library(here)
library(logging)
library(httr)
library(jsonlite)

source(here("r", "config", "connections.R"))

# Global flag to enable/disable email operations
# Set to TRUE when ready for production email integration
ENABLE_EMAIL_OPERATIONS <- FALSE

# Function to check if email operations are enabled
is_email_enabled <- function() {
  return(ENABLE_EMAIL_OPERATIONS)
}

# Function to send pipeline notification
send_pipeline_notification <- function(status, message, details = NULL, run_id = "", attachments = NULL) {
  
  if (!is_email_enabled()) {
    loginfo("Email operations disabled - skipping notification")
    return(list(status = "Skipped", message = "Email operations disabled"))
  }
  
  tryCatch({
    # Get email configuration
    email_config <- get_email_config()
    
    if (is.null(email_config)) {
      logwarn("Email configuration not available - skipping notification")
      return(list(status = "Skipped", message = "Email configuration not available"))
    }
    
    # Create email subject
    subject <- paste("Qualark Pipeline", status, "-", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
    if (run_id != "") {
      subject <- paste(subject, "- Run ID:", run_id)
    }
    
    # Create email body
    body <- create_email_body(status, message, details, run_id)
    
    # Send email
    send.mail(
      from = email_config$from,
      to = email_config$to,
      subject = subject,
      body = body,
      html = TRUE,
      smtp = list(
        host.name = email_config$smtp_server,
        port = email_config$port,
        user.name = email_config$username,
        passwd = email_config$password,
        ssl = TRUE
      ),
      attach.files = attachments
    )
    
    loginfo(paste("Email notification sent successfully:", status))
    return(list(status = "Success", message = "Email notification sent"))
    
  }, error = function(e) {
    logerror(paste("Error sending email notification:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to create comprehensive email body
create_email_body <- function(status, message, details = NULL, run_id = "") {
  
  # Status color coding
  status_colors <- list(
    "SUCCESS" = "#28a745",
    "ERROR" = "#dc3545", 
    "WARNING" = "#ffc107",
    "INFO" = "#17a2b8",
    "FAILED" = "#dc3545",
    "SuccessWithErrorFiles" = "#ffc107"
  )
  
  color <- status_colors[[status]] %||% "#6c757d"
  
  body <- paste0(
    "<!DOCTYPE html>",
    "<html><head><style>",
    "body { font-family: Arial, sans-serif; margin: 20px; }",
    ".header { background-color: ", color, "; color: white; padding: 15px; border-radius: 5px; }",
    ".content { margin: 20px 0; }",
    ".details { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }",
    ".footer { font-size: 12px; color: #6c757d; margin-top: 30px; }",
    "table { border-collapse: collapse; width: 100%; }",
    "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
    "th { background-color: #f2f2f2; }",
    "</style></head><body>",
    
    "<div class='header'>",
    "<h2>Qualark Pipeline Notification</h2>",
    "<p><strong>Status:</strong> ", status, "</p>",
    "<p><strong>Time:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>",
    if (run_id != "") paste0("<p><strong>Run ID:</strong> ", run_id, "</p>"),
    "</div>",
    
    "<div class='content'>",
    "<h3>Message</h3>",
    "<p>", message, "</p>"
  )
  
  # Add details if provided
  if (!is.null(details) && length(details) > 0) {
    body <- paste0(body, "<h3>Details</h3><div class='details'>")
    
    if (is.list(details)) {
      # Create table for structured details
      body <- paste0(body, "<table><tr><th>Component</th><th>Status</th><th>Message</th></tr>")
      for (name in names(details)) {
        detail <- details[[name]]
        if (is.list(detail)) {
          status_text <- detail$status %||% "Unknown"
          message_text <- detail$message %||% ""
        } else {
          status_text <- "Info"
          message_text <- as.character(detail)
        }
        body <- paste0(body, "<tr><td>", name, "</td><td>", status_text, "</td><td>", message_text, "</td></tr>")
      }
      body <- paste0(body, "</table>")
    } else {
      # Simple list for basic details
      body <- paste0(body, "<ul>")
      for (detail in details) {
        body <- paste0(body, "<li>", detail, "</li>")
      }
      body <- paste0(body, "</ul>")
    }
    
    body <- paste0(body, "</div>")
  }
  
  # Add system information
  body <- paste0(body, 
    "<h3>System Information</h3>",
    "<div class='details'>",
    "<p><strong>R Version:</strong> ", R.version.string, "</p>",
    "<p><strong>Platform:</strong> ", R.version$platform, "</p>",
    "<p><strong>Working Directory:</strong> ", getwd(), "</p>",
    "</div>"
  )
  
  body <- paste0(body,
    "</div>",
    
    "<div class='footer'>",
    "<p>This is an automated message from the Qualark Data Processing Pipeline.</p>",
    "<p>For support or questions, contact the development team.</p>",
    "</div>",
    
    "</body></html>"
  )
  
  return(body)
}

# Function to send comprehensive pipeline report
send_pipeline_report <- function(pipeline_results, run_id = "") {
  
  if (!is_email_enabled()) {
    loginfo("Email operations disabled - skipping pipeline report")
    return(list(status = "Skipped", message = "Email operations disabled"))
  }
  
  # Determine overall status
  overall_status <- "SUCCESS"
  if (pipeline_results$summary$failed_runs > 0) {
    overall_status <- "FAILED"
  } else if (pipeline_results$summary$successful_runs < pipeline_results$summary$total_runs) {
    overall_status <- "WARNING"
  }
  
  # Create detailed message
  message <- paste0(
    "Pipeline execution completed with ", 
    pipeline_results$summary$successful_runs, " successful runs and ",
    pipeline_results$summary$failed_runs, " failed runs."
  )
  
  # Create details from pipeline results
  details <- list()
  for (pipeline_name in names(pipeline_results$pipeline_results)) {
    result <- pipeline_results$pipeline_results[[pipeline_name]]
    details[[pipeline_name]] <- list(
      status = result$status,
      message = result$message
    )
  }
  
  return(send_pipeline_notification(
    status = overall_status,
    message = message,
    details = details,
    run_id = run_id
  ))
}

# Function to send error notification with detailed information
send_error_notification <- function(error_message, error_details = NULL, run_id = "", error_file = NULL) {
  
  attachments <- NULL
  if (!is.null(error_file) && file.exists(error_file)) {
    attachments <- error_file
  }
  
  return(send_pipeline_notification(
    status = "ERROR",
    message = error_message,
    details = error_details,
    run_id = run_id,
    attachments = attachments
  ))
}

# Function to send success notification
send_success_notification <- function(success_message, details = NULL, run_id = "") {
  
  return(send_pipeline_notification(
    status = "SUCCESS",
    message = success_message,
    details = details,
    run_id = run_id
  ))
}

# Function to send warning notification
send_warning_notification <- function(warning_message, details = NULL, run_id = "") {
  
  return(send_pipeline_notification(
    status = "WARNING",
    message = warning_message,
    details = details,
    run_id = run_id
  ))
}

# Function to send data quality report
send_data_quality_report <- function(validation_results, run_id = "") {
  
  if (!is_email_enabled()) {
    loginfo("Email operations disabled - skipping data quality report")
    return(list(status = "Skipped", message = "Email operations disabled"))
  }
  
  # Count validation results
  total_files <- length(validation_results)
  passed_files <- sum(sapply(validation_results, function(x) x$status == "Pass"))
  failed_files <- total_files - passed_files
  
  # Determine status
  if (failed_files == 0) {
    status <- "SUCCESS"
    message <- paste("Data quality validation passed for all", total_files, "files")
  } else {
    status <- "WARNING"
    message <- paste("Data quality validation completed with", failed_files, "of", total_files, "files failing validation")
  }
  
  return(send_pipeline_notification(
    status = status,
    message = message,
    details = validation_results,
    run_id = run_id
  ))
}

# Function to send daily summary report
send_daily_summary <- function(summary_data, run_id = "") {
  
  if (!is_email_enabled()) {
    loginfo("Email operations disabled - skipping daily summary")
    return(list(status = "Skipped", message = "Email operations disabled"))
  }
  
  message <- paste0(
    "Daily pipeline summary for ", format(Sys.Date(), "%Y-%m-%d"), 
    ": ", summary_data$total_runs, " total runs, ",
    summary_data$successful_runs, " successful, ",
    summary_data$failed_runs, " failed"
  )
  
  return(send_pipeline_notification(
    status = "INFO",
    message = message,
    details = summary_data,
    run_id = run_id
  ))
}

# Legacy functions for backward compatibility
send_file_upload_notification <- function(filename, run_id) {
  return(send_success_notification(
    paste("File", filename, "uploaded successfully and pipeline initiated"),
    run_id = run_id
  ))
}

send_incorrect_file_notification <- function(filename) {
  return(send_error_notification(
    paste("Incorrect file uploaded:", filename),
    details = list(
      "File does not meet naming convention",
      "Please ensure file follows format: Qualark_2023_DIDSON_Counts.xlsx",
      "Re-upload the correct version"
    )
  ))
}

# Function to enable email operations (flip switch)
enable_email_operations <- function() {
  ENABLE_EMAIL_OPERATIONS <<- TRUE
  loginfo("Email operations ENABLED - all email functions will now execute")
}

# Function to disable email operations (flip switch)
disable_email_operations <- function() {
  ENABLE_EMAIL_OPERATIONS <<- FALSE
  loginfo("Email operations DISABLED - all email functions will be skipped")
}

# Function to check email status
get_email_status <- function() {
  if (!is_email_enabled()) {
    return(list(enabled = FALSE, message = "Email operations are disabled"))
  }
  
  email_config <- get_email_config()
  if (is.null(email_config)) {
    return(list(enabled = TRUE, configured = FALSE, message = "Email operations enabled but configuration missing"))
  }
  
  return(list(enabled = TRUE, configured = TRUE, message = "Email operations enabled and configured"))
}

# Test function
if (interactive()) {
  # Test email status
  status <- get_email_status()
  cat("Email Status:", status$message, "\n")
  
  # Test enabling/disabling
  disable_email_operations()
  cat("Email operations disabled\n")
  
  enable_email_operations()
  cat("Email operations enabled\n")
}