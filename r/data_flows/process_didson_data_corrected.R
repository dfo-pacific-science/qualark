# Process DIDSON Data (Corrected with CSV Integration)
# Uses the parsed CSV files instead of Excel files directly

library(dplyr)
library(readr)
library(tidyr)
library(here)

source(here("r", "config", "connections.R"))

# Function to process DIDSON data from CSV files
process_didson_data_from_csv <- function(run_id = "") {
  
  cat("Processing DIDSON data from CSV files...\n")
  
  # Load the DIDSON CSV files
  didson_files <- list.files("data/csv_parsed/main_data", 
                             pattern = "Qualark_2023_DIDSON_Counts.*_with_headers\\.csv$", 
                             full.names = TRUE)
  
  if (length(didson_files) == 0) {
    stop("No DIDSON CSV files found in data/csv_parsed/main_data/")
  }
  
  cat("  Found", length(didson_files), "DIDSON CSV files\n")
  
  # Process each DIDSON file
  all_didson_data <- data.frame()
  
  for (file in didson_files) {
    cat("  Processing:", basename(file), "\n")
    
    tryCatch({
      # Read the CSV file
      data <- read_csv(file, show_col_types = FALSE)
      
      # Skip the header row (row 1 contains the actual column names)
      if (nrow(data) > 1) {
        data <- data[-1, ]
      }
      
      # Convert data types
      data <- data %>%
        mutate(
          Date = as.Date(as.numeric(Date), origin = "1899-12-30"),
          Count_Hour = as.numeric(Count_Hour),
          Duration = as.numeric(Duration),
          Up = as.numeric(Up),
          Down = as.numeric(Down),
          Net_Up = as.numeric(Net_Up),
          Salmon_Hour = as.numeric(Salmon_Hour)
        ) %>%
        rename(
          date = Date,
          count_hour = Count_Hour,
          duration_minutes = Duration,
          up = Up,
          down = Down,
          net_up = Net_Up,
          salmon_per_hour = Salmon_Hour,
          comments = Comments
        )
      
      # Filter valid data
      valid_data <- data %>%
        filter(
          !is.na(date),
          !is.na(count_hour),
          count_hour >= 0,
          count_hour <= 23,
          !is.na(up),
          up >= 0,
          !is.na(down),
          down >= 0
        )
      
      # Add sheet identifier
      sheet_name <- gsub(".*_([^_]+)_with_headers\\.csv$", "\\1", basename(file))
      valid_data$sheet_name <- sheet_name
      
      all_didson_data <- rbind(all_didson_data, valid_data)
      
      cat("    Processed", nrow(valid_data), "valid rows\n")
      
    }, error = function(e) {
      cat("    Error processing", basename(file), ":", e$message, "\n")
    })
  }
  
  if (nrow(all_didson_data) == 0) {
    stop("No valid DIDSON data was processed")
  }
  
  cat("  Total DIDSON records processed:", nrow(all_didson_data), "\n")
  
  # Save processed data
  output_path <- get_file_path("silver", "processed_from_csv", 
                              paste0("didson_processed_", run_id, ".csv"))
  
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(all_didson_data, output_path, row.names = FALSE)
  
  cat("  Saved processed DIDSON data to:", output_path, "\n")
  
  return(all_didson_data)
}

# Function to process sonar counts data
process_sonar_counts_data <- function(didson_data, run_id = "") {
  
  cat("Processing sonar counts data...\n")
  
  # Create sonar counts summary
  sonar_counts <- didson_data %>%
    group_by(date, sheet_name) %>%
    summarise(
      total_up = sum(up, na.rm = TRUE),
      total_down = sum(down, na.rm = TRUE),
      total_net_up = sum(net_up, na.rm = TRUE),
      total_salmon_hour = sum(salmon_per_hour, na.rm = TRUE),
      avg_duration = mean(duration_minutes, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      created_at = Sys.time(),
      updated_at = Sys.time(),
      updated_by = "csv_processor"
    )
  
  cat("  Created", nrow(sonar_counts), "sonar count records\n")
  
  # Save sonar counts data
  output_path <- get_file_path("silver", "processed_from_csv", 
                              paste0("sonar_counts_processed_", run_id, ".csv"))
  
  write.csv(sonar_counts, output_path, row.names = FALSE)
  
  cat("  Saved sonar counts data to:", output_path, "\n")
  
  return(sonar_counts)
}

# Main function to process all DIDSON data
process_all_didson_data <- function() {
  
  cat("Processing all DIDSON data from CSV files...\n")
  cat("==========================================\n\n")
  
  run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Step 1: Process DIDSON data
  didson_data <- process_didson_data_from_csv(run_id)
  
  # Step 2: Process sonar counts data
  sonar_counts_data <- process_sonar_counts_data(didson_data, run_id)
  
  # Summary
  cat("\n=== DIDSON PROCESSING SUMMARY ===\n")
  cat("DIDSON data processed:", nrow(didson_data), "records\n")
  cat("Sonar counts created:", nrow(sonar_counts_data), "records\n")
  cat("Run ID:", run_id, "\n")
  
  return(list(
    didson_data = didson_data,
    sonar_counts_data = sonar_counts_data,
    run_id = run_id
  ))
}

# Test function
if (interactive()) {
  results <- process_all_didson_data()
}
