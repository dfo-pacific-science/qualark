# SharePoint Integration for Qualark Pipeline
# Handles uploading raw Excel files to SharePoint for provenance

library(httr)
library(jsonlite)
library(here)
library(logging)

source(here("r", "config", "connections.R"))

# Global flag to enable/disable SharePoint operations
# Set to TRUE when ready for production SharePoint integration
ENABLE_SHAREPOINT_OPERATIONS <- FALSE

# Function to check if SharePoint operations are enabled
is_sharepoint_enabled <- function() {
  return(ENABLE_SHAREPOINT_OPERATIONS)
}

# Function to get SharePoint access token
get_sharepoint_token <- function() {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - returning NULL token")
    return(NULL)
  }
  
  tryCatch({
    # This would typically use Microsoft365R or similar package
    # For now, we'll use a placeholder that can be configured
    token <- Sys.getenv("SHAREPOINT_TOKEN")
    if (token == "") {
      logerror("SharePoint token not found in environment variables")
      return(NULL)
    }
    return(token)
  }, error = function(e) {
    logerror(paste("Error getting SharePoint token:", e$message))
    return(NULL)
  })
}

# Function to upload file to SharePoint
upload_file_to_sharepoint <- function(file_path, folder_path = "Qualark Data/Raw Files", run_id = "") {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - skipping file upload")
    return(list(status = "Skipped", message = "SharePoint operations disabled"))
  }
  
  if (!file.exists(file_path)) {
    return(list(status = "Error", message = "File not found"))
  }
  
  token <- get_sharepoint_token()
  if (is.null(token)) {
    return(list(status = "Error", message = "SharePoint authentication failed"))
  }
  
  tryCatch({
    # Create folder path with run_id for organization
    full_folder_path <- paste0(folder_path, "/", run_id)
    
    # Upload file using Microsoft Graph API
    # This is a simplified version - in production, you'd use Microsoft365R
    file_name <- basename(file_path)
    file_content <- readBin(file_path, "raw", file.info(file_path)$size)
    
    # Microsoft Graph API endpoint for uploading files
    upload_url <- paste0(
      "https://graph.microsoft.com/v1.0/sites/",
      Sys.getenv("SHAREPOINT_SITE_ID"),
      "/drive/root:/",
      full_folder_path,
      "/",
      file_name,
      ":/content"
    )
    
    # Upload file
    response <- PUT(
      url = upload_url,
      add_headers(
        Authorization = paste("Bearer", token),
        "Content-Type" = "application/octet-stream"
      ),
      body = file_content
    )
    
    if (status_code(response) %in% c(200, 201)) {
      loginfo(paste("Successfully uploaded", file_name, "to SharePoint"))
      return(list(status = "Success", message = paste("Uploaded", file_name, "to SharePoint")))
    } else {
      logerror(paste("SharePoint upload failed with status:", status_code(response)))
      return(list(status = "Error", message = paste("Upload failed with status:", status_code(response))))
    }
    
  }, error = function(e) {
    logerror(paste("Error uploading file to SharePoint:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to upload all raw Excel files to SharePoint
upload_raw_files_to_sharepoint <- function(run_id = "") {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - skipping raw files upload")
    return(list(status = "Skipped", message = "SharePoint operations disabled"))
  }
  
  loginfo("Uploading raw Excel files to SharePoint for provenance")
  
  # Find all Excel files in prototype_data
  excel_files <- list.files("prototype_data", pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)
  
  if (length(excel_files) == 0) {
    logwarn("No Excel files found to upload")
    return(list(status = "Warning", message = "No Excel files found"))
  }
  
  results <- list()
  success_count <- 0
  
  for (file_path in excel_files) {
    file_name <- basename(file_path)
    loginfo(paste("Uploading", file_name, "to SharePoint"))
    
    result <- upload_file_to_sharepoint(file_path, run_id = run_id)
    results[[file_name]] <- result
    
    if (result$status == "Success") {
      success_count <- success_count + 1
    }
  }
  
  loginfo(paste("SharePoint upload completed:", success_count, "of", length(excel_files), "files uploaded successfully"))
  
  return(list(
    status = ifelse(success_count == length(excel_files), "Success", "Partial"),
    message = paste("Uploaded", success_count, "of", length(excel_files), "files"),
    details = results
  ))
}

# Function to create SharePoint folder structure
create_sharepoint_folders <- function(run_id = "") {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - skipping folder creation")
    return(list(status = "Skipped", message = "SharePoint operations disabled"))
  }
  
  tryCatch({
    token <- get_sharepoint_token()
    if (is.null(token)) {
      return(list(status = "Error", message = "SharePoint authentication failed"))
    }
    
    # Create folder structure
    folders <- c(
      paste0("Qualark Data/Raw Files/", run_id),
      paste0("Qualark Data/Processed Data/", run_id),
      paste0("Qualark Data/Error Files/", run_id),
      paste0("Qualark Data/Reports/", run_id)
    )
    
    created_folders <- 0
    for (folder in folders) {
      # Microsoft Graph API endpoint for creating folders
      create_url <- paste0(
        "https://graph.microsoft.com/v1.0/sites/",
        Sys.getenv("SHAREPOINT_SITE_ID"),
        "/drive/root:/",
        folder,
        ":/children"
      )
      
      folder_body <- list(
        name = basename(folder),
        folder = list(),
        `@microsoft.graph.conflictBehavior` = "rename"
      )
      
      response <- POST(
        url = create_url,
        add_headers(
          Authorization = paste("Bearer", token),
          "Content-Type" = "application/json"
        ),
        body = toJSON(folder_body, auto_unbox = TRUE)
      )
      
      if (status_code(response) %in% c(200, 201)) {
        created_folders <- created_folders + 1
        loginfo(paste("Created SharePoint folder:", folder))
      } else {
        logwarn(paste("Failed to create folder:", folder, "Status:", status_code(response)))
      }
    }
    
    return(list(
      status = "Success",
      message = paste("Created", created_folders, "of", length(folders), "folders")
    ))
    
  }, error = function(e) {
    logerror(paste("Error creating SharePoint folders:", e$message))
    return(list(status = "Error", message = e$message))
  })
}

# Function to upload processed data to SharePoint
upload_processed_data_to_sharepoint <- function(run_id = "") {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - skipping processed data upload")
    return(list(status = "Skipped", message = "SharePoint operations disabled"))
  }
  
  loginfo("Uploading processed data to SharePoint")
  
  # Find processed data files
  processed_files <- list.files("data/silver/processed_from_csv", pattern = "\\.csv$", full.names = TRUE)
  
  if (length(processed_files) == 0) {
    logwarn("No processed data files found to upload")
    return(list(status = "Warning", message = "No processed data files found"))
  }
  
  results <- list()
  success_count <- 0
  
  for (file_path in processed_files) {
    file_name <- basename(file_path)
    loginfo(paste("Uploading processed data:", file_name))
    
    result <- upload_file_to_sharepoint(
      file_path, 
      folder_path = paste0("Qualark Data/Processed Data/", run_id),
      run_id = run_id
    )
    results[[file_name]] <- result
    
    if (result$status == "Success") {
      success_count <- success_count + 1
    }
  }
  
  return(list(
    status = ifelse(success_count == length(processed_files), "Success", "Partial"),
    message = paste("Uploaded", success_count, "of", length(processed_files), "processed files"),
    details = results
  ))
}

# Function to upload error files to SharePoint
upload_error_files_to_sharepoint <- function(run_id = "") {
  if (!is_sharepoint_enabled()) {
    loginfo("SharePoint operations disabled - skipping error files upload")
    return(list(status = "Skipped", message = "SharePoint operations disabled"))
  }
  
  loginfo("Uploading error files to SharePoint")
  
  # Find error files
  error_files <- list.files("data/silver/error_logs", pattern = "\\.csv$", full.names = TRUE)
  
  if (length(error_files) == 0) {
    loginfo("No error files found to upload")
    return(list(status = "Success", message = "No error files to upload"))
  }
  
  results <- list()
  success_count <- 0
  
  for (file_path in error_files) {
    file_name <- basename(file_path)
    loginfo(paste("Uploading error file:", file_name))
    
    result <- upload_file_to_sharepoint(
      file_path, 
      folder_path = paste0("Qualark Data/Error Files/", run_id),
      run_id = run_id
    )
    results[[file_name]] <- result
    
    if (result$status == "Success") {
      success_count <- success_count + 1
    }
  }
  
  return(list(
    status = ifelse(success_count == length(error_files), "Success", "Partial"),
    message = paste("Uploaded", success_count, "of", length(error_files), "error files"),
    details = results
  ))
}

# Function to enable SharePoint operations (flip switch)
enable_sharepoint_operations <- function() {
  ENABLE_SHAREPOINT_OPERATIONS <<- TRUE
  loginfo("SharePoint operations ENABLED - all SharePoint functions will now execute")
}

# Function to disable SharePoint operations (flip switch)
disable_sharepoint_operations <- function() {
  ENABLE_SHAREPOINT_OPERATIONS <<- FALSE
  loginfo("SharePoint operations DISABLED - all SharePoint functions will be skipped")
}

# Function to check SharePoint status
get_sharepoint_status <- function() {
  if (!is_sharepoint_enabled()) {
    return(list(enabled = FALSE, message = "SharePoint operations are disabled"))
  }
  
  token <- get_sharepoint_token()
  if (is.null(token)) {
    return(list(enabled = TRUE, authenticated = FALSE, message = "SharePoint operations enabled but authentication failed"))
  }
  
  return(list(enabled = TRUE, authenticated = TRUE, message = "SharePoint operations enabled and authenticated"))
}

# Test function
if (interactive()) {
  # Test SharePoint status
  status <- get_sharepoint_status()
  cat("SharePoint Status:", status$message, "\n")
  
  # Test enabling/disabling
  disable_sharepoint_operations()
  cat("SharePoint operations disabled\n")
  
  enable_sharepoint_operations()
  cat("SharePoint operations enabled\n")
}
