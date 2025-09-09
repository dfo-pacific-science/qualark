# Email Notification Utilities
# Replaces Logic Apps email functionality

library(mailR)
library(here)

source(here("r", "config", "connections.R"))

# Function to send pipeline notification email
send_pipeline_notification <- function(notification_data, logic_app_url = "") {
  
  # If logic_app_url is provided, send HTTP request (equivalent to Logic App)
  if (logic_app_url != "") {
    send_http_notification(notification_data, logic_app_url)
    return()
  }
  
  # Otherwise, send email directly
  send_email_notification(notification_data)
}

# Function to send HTTP notification (replaces Logic App call)
send_http_notification <- function(notification_data, url) {
  
  library(httr)
  library(jsonlite)
  
  tryCatch({
    
    # Prepare the request body
    request_body <- list(
      PipelineStatus = notification_data$PipelineStatus,
      PipelineRunId = notification_data$PipelineRunId,
      AzureFileLocation = notification_data$AzureFileLocation,
      SharePointFolder = notification_data$SharePointFolder,
      Extension = notification_data$Extension
    )
    
    # Send POST request
    response <- POST(
      url = url,
      body = request_body,
      encode = "json",
      add_headers("Content-Type" = "application/json")
    )
    
    if (status_code(response) == 200) {
      cat("Successfully sent HTTP notification\n")
    } else {
      cat("HTTP notification failed with status:", status_code(response), "\n")
    }
    
  }, error = function(e) {
    cat("Error sending HTTP notification:", e$message, "\n")
  })
}

# Function to send email notification
send_email_notification <- function(notification_data) {
  
  tryCatch({
    
    # Determine email content based on status
    if (notification_data$PipelineStatus == "Success") {
      subject <- "Pipeline Processed Successfully"
      body <- create_success_email_body(notification_data)
    } else if (notification_data$PipelineStatus == "SuccessWithErrorFiles") {
      subject <- paste("Pipeline Processed with Errors -", notification_data$PipelineRunId)
      body <- create_success_with_errors_email_body(notification_data)
    } else if (notification_data$PipelineStatus == "Failed") {
      subject <- "Pipeline Processing Failed"
      body <- create_failed_email_body(notification_data)
    } else {
      subject <- "Pipeline Status Unknown"
      body <- create_unknown_status_email_body(notification_data)
    }
    
    # Send email
    send.mail(
      from = email_config$from,
      to = email_config$to,
      subject = subject,
      body = body,
      smtp = list(
        host.name = email_config$smtp_server,
        port = email_config$port,
        user.name = email_config$username,
        passwd = email_config$password,
        ssl = TRUE
      ),
      authenticate = TRUE,
      send = TRUE
    )
    
    cat("Successfully sent email notification\n")
    
  }, error = function(e) {
    cat("Error sending email notification:", e$message, "\n")
  })
}

# Email body templates
create_success_email_body <- function(data) {
  paste0(
    "<p>Dear Team,<br><br>",
    "The pipeline completed successfully!<br>",
    "Pipeline run ID: ", data$PipelineRunId, "<br><br>",
    "No errors encountered.<br><br>",
    "Thank you,<br>",
    "Your Automated System</p>"
  )
}

create_success_with_errors_email_body <- function(data) {
  paste0(
    "<p>Dear Team,<br><br>",
    "The pipeline completed with errors.<br>",
    "Pipeline run ID: ", data$PipelineRunId, "<br><br>",
    "Error files have been generated.<br>",
    "Please review these files.<br><br>",
    "Thank you,<br>",
    "Your Automated System</p>"
  )
}

create_failed_email_body <- function(data) {
  paste0(
    "<p>Dear Team,<br><br>",
    "The pipeline has failed.<br>",
    "Pipeline run ID: ", data$PipelineRunId, "<br><br>",
    "Please check error logs for diagnosis.<br><br>",
    "Thank you,<br>",
    "Your Automated System</p>"
  )
}

create_unknown_status_email_body <- function(data) {
  paste0(
    "<p>Dear Team,<br><br>",
    "The pipeline completed with unknown status: ", data$PipelineStatus, "<br>",
    "Pipeline run ID: ", data$PipelineRunId, "<br><br>",
    "Please investigate.<br><br>",
    "Thank you,<br>",
    "Your Automated System</p>"
  )
}

# Function to send file upload notification
send_file_upload_notification <- function(filename, run_id) {
  
  subject <- paste("File Loaded and Pipeline Initiated - runID:", run_id)
  body <- paste0(
    "<p>Dear Team,<br><br>",
    "This is to notify you that the file \"", filename, "\" has been successfully loaded, ",
    "and the corresponding data pipeline has been initiated, the reference run ID is: ", run_id, "<br><br>",
    "Thank you,<br>",
    "Your Automated System</p>"
  )
  
  tryCatch({
    send.mail(
      from = email_config$from,
      to = email_config$to,
      subject = subject,
      body = body,
      smtp = list(
        host.name = email_config$smtp_server,
        port = email_config$port,
        user.name = email_config$username,
        passwd = email_config$password,
        ssl = TRUE
      ),
      authenticate = TRUE,
      send = TRUE
    )
    
    cat("Successfully sent file upload notification\n")
    
  }, error = function(e) {
    cat("Error sending file upload notification:", e$message, "\n")
  })
}

# Function to send error notification for incorrect file
send_incorrect_file_notification <- function(filename) {
  
  subject <- "Action Required: Incorrect File Uploaded"
  body <- paste0(
    "<p>Dear Team,<br><br>",
    "It appears that the file \"", filename, "\" does not meet the required naming convention. ",
    "Please ensure that the file follows the correct format (for example, \"Qualark_2023_DIDSON_Counts.xlsx\") ",
    "and re-upload the correct version.<br><br>",
    "Thank you for your prompt attention to this matter,<br>",
    "Your Automated System</p>"
  )
  
  tryCatch({
    send.mail(
      from = email_config$from,
      to = email_config$to,
      subject = subject,
      body = body,
      smtp = list(
        host.name = email_config$smtp_server,
        port = email_config$port,
        user.name = email_config$username,
        passwd = email_config$password,
        ssl = TRUE
      ),
      authenticate = TRUE,
      send = TRUE
    )
    
    cat("Successfully sent incorrect file notification\n")
    
  }, error = function(e) {
    cat("Error sending incorrect file notification:", e$message, "\n")
  })
}
