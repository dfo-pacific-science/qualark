# Error Handling Utilities
# Provides error handling and logging functionality

library(logging)
library(here)

# Function to handle errors gracefully
handle_error <- function(error, context = "") {
  
  error_message <- paste("Error in", context, ":", error$message)
  logerror(error_message)
  
  # Create error log entry
  error_log <- list(
    timestamp = Sys.time(),
    context = context,
    error_message = error$message,
    call_stack = deparse(error$call)
  )
  
  # Save error log
  save_error_log(error_log)
  
  return(error_log)
}

# Function to save error logs
save_error_log <- function(error_log) {
  
  error_log_path <- get_file_path("silver", "error_logs", 
                                 paste0("error_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json"))
  
  dir.create(dirname(error_log_path), recursive = TRUE, showWarnings = FALSE)
  
  # Convert to JSON and save
  error_json <- jsonlite::toJSON(error_log, pretty = TRUE)
  writeLines(error_json, error_log_path)
  
  cat("Error log saved to:", error_log_path, "\n")
}

# Function to validate data quality
validate_data_quality <- function(data, validation_rules) {
  
  validation_results <- list(
    total_rows = nrow(data),
    valid_rows = 0,
    errors = list(),
    warnings = list()
  )
  
  # Apply validation rules
  for (rule in validation_rules) {
    rule_result <- apply_validation_rule(data, rule)
    
    if (rule_result$type == "error") {
      validation_results$errors <- append(validation_results$errors, rule_result$message)
    } else if (rule_result$type == "warning") {
      validation_results$warnings <- append(validation_results$warnings, rule_result$message)
    }
  }
  
  # Count valid rows
  validation_results$valid_rows <- nrow(data) - length(validation_results$errors)
  validation_results$invalid_rows <- length(validation_results$errors)
  
  return(validation_results)
}

# Function to apply individual validation rule
apply_validation_rule <- function(data, rule) {
  
  tryCatch({
    
    if (rule$type == "required_columns") {
      missing_cols <- setdiff(rule$columns, names(data))
      if (length(missing_cols) > 0) {
        return(list(
          type = "error",
          message = paste("Missing required columns:", paste(missing_cols, collapse = ", "))
        ))
      }
    }
    
    if (rule$type == "data_type") {
      for (col in rule$columns) {
        if (col %in% names(data)) {
          expected_type <- rule$expected_type
          actual_type <- class(data[[col]])[1]
          
          if (actual_type != expected_type) {
            return(list(
              type = "warning",
              message = paste("Column", col, "has type", actual_type, "but expected", expected_type)
            ))
          }
        }
      }
    }
    
    if (rule$type == "range_check") {
      for (col in rule$columns) {
        if (col %in% names(data)) {
          values <- data[[col]]
          if (is.numeric(values)) {
            if (any(values < rule$min_value, na.rm = TRUE)) {
              return(list(
                type = "error",
                message = paste("Column", col, "has values below minimum", rule$min_value)
              ))
            }
            if (any(values > rule$max_value, na.rm = TRUE)) {
              return(list(
                type = "error",
                message = paste("Column", col, "has values above maximum", rule$max_value)
              ))
            }
          }
        }
      }
    }
    
    if (rule$type == "not_null") {
      for (col in rule$columns) {
        if (col %in% names(data)) {
          null_count <- sum(is.na(data[[col]]))
          if (null_count > 0) {
            return(list(
              type = "warning",
              message = paste("Column", col, "has", null_count, "null values")
            ))
          }
        }
      }
    }
    
    return(list(type = "success", message = "Validation passed"))
    
  }, error = function(e) {
    return(list(
      type = "error",
      message = paste("Validation rule failed:", e$message)
    ))
  })
}

# Function to create error files
create_error_file <- function(error_data, run_id, error_type) {
  
  error_filename <- paste0("error_", error_type, "_", run_id, ".csv")
  error_path <- get_file_path("bronze", "error_files", error_filename)
  
  dir.create(dirname(error_path), recursive = TRUE, showWarnings = FALSE)
  
  # Write error data to CSV
  write.csv(error_data, error_path, row.names = FALSE)
  
  cat("Error file created:", error_path, "\n")
  
  return(error_path)
}

# Function to retry operations
retry_operation <- function(operation, max_retries = 3, delay = 1) {
  
  for (attempt in 1:max_retries) {
    
    tryCatch({
      result <- operation()
      return(result)
      
    }, error = function(e) {
      
      if (attempt == max_retries) {
        logerror(paste("Operation failed after", max_retries, "attempts:", e$message))
        stop(e)
      } else {
        logwarn(paste("Operation failed, attempt", attempt, "of", max_retries, ":", e$message))
        Sys.sleep(delay * attempt)  # Exponential backoff
      }
    })
  }
}

# Function to check file integrity
check_file_integrity <- function(file_path) {
  
  if (!file.exists(file_path)) {
    return(list(valid = FALSE, message = "File does not exist"))
  }
  
  file_size <- file.size(file_path)
  if (file_size == 0) {
    return(list(valid = FALSE, message = "File is empty"))
  }
  
  # Check if file is readable
  tryCatch({
    readLines(file_path, n = 1)
    return(list(valid = TRUE, message = "File is valid"))
  }, error = function(e) {
    return(list(valid = FALSE, message = paste("File is not readable:", e$message)))
  })
}

# Function to monitor system resources (simplified)
monitor_system_resources <- function() {
  
  system_info <- list(
    timestamp = Sys.time(),
    memory_usage = gc()[2, 2],  # Use R's garbage collection instead of Windows-specific functions
    platform = R.version$platform
  )
  
  return(system_info)
}
