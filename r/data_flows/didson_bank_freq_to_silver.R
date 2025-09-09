# DIDSON Bank Frequency to Silver Data Flow
# Converts ADF dataflow: df_didson_bank_freq_to_silver

library(dplyr)
library(readxl)
library(lubridate)
library(here)

source(here("r", "config", "connections.R"))

# Function to process DIDSON bank frequency data
process_didson_bank_freq <- function(input_file_path, run_id = "") { 
  # Read the Excel file from bronze layer
  cat("Reading DIDSON bank frequency data from:", input_file_path, "\n")
  # Read the specific sheet (LB HF, RB HF, etc.)
  data <- read_excel(input_file_path, sheet = "LB HF", range = "A4:H1000")
  
  # Rename columns to match the ADF transformation
  data_renamed <- data %>%
    rename(
      date = Date,
      count_hour = `Count Hour`,
      duration_minutes = Duration,
      up = Up,
      down = Down,
      net_up = `Net Up`,
      salmon_per_hour = `Salmon/Hour`,
      comments = Comments
    )
  
  # Apply filters (equivalent to ADF filter1)
  data_filtered <- data_renamed %>%
    filter(
      !is.na(date),
      !is.na(as.Date(date, format = "%Y-%m-%d")),
      !is.na(count_hour),
      as.numeric(count_hour) >= 0,
      as.numeric(count_hour) <= 23,
      !is.na(up),
      as.numeric(up) >= 0,
      !is.na(down),
      as.numeric(down) >= 0
    ) %>%
    mutate(
      # Convert to proper data types
      date = as.Date(date),
      count_hour = as.numeric(count_hour),
      duration_minutes = as.numeric(duration_minutes),
      up = as.numeric(up),
      down = as.numeric(down),
      net_up = as.numeric(net_up),
      salmon_per_hour = as.numeric(salmon_per_hour)
    )
  
  # Add run_id if provided
  if (run_id != "") {
    data_filtered$run_id <- run_id
  }
  
  # Save to silver layer
  output_path <- get_file_path("silver", "didson_processed", 
                               paste0("didson_bank_freq_", run_id, ".csv"))
  
  # Ensure directory exists
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  
  write.csv(data_filtered, output_path, row.names = FALSE)
  
  cat("Processed data saved to:", output_path, "\n")
  cat("Rows processed:", nrow(data_filtered), "\n")
  
  return(data_filtered)
}

# Function to process all DIDSON sheets
process_all_didson_sheets <- function(input_folder, run_id = "") {
  
  sheets <- c("LB HF", "LB LF", "LB LF LR", "RB HF", "RB LF", "RB LF LR")
  all_data <- list()
  
  for (sheet in sheets) {
    cat("Processing sheet:", sheet, "\n")
    
    # Find the Excel file in the input folder
    excel_files <- list.files(input_folder, pattern = "\\.xlsx$", full.names = TRUE)
    
    if (length(excel_files) == 0) {
      warning("No Excel files found in:", input_folder)
      next
    }
    
    # Use the first Excel file found
    excel_file <- excel_files[1]
    tryCatch({
      # Read the specific sheet
      data <- read_excel(excel_file, sheet = sheet, range = "A4:H1000")
      # Rename columns
      data_renamed <- data %>%
        rename(
          date = Date,
          count_hour = `Count Hour`,
          duration_minutes = Duration,
          up = Up,
          down = Down,
          net_up = `Net Up`,
          salmon_per_hour = `Salmon/Hour`,
          comments = Comments
        )
      
      # Apply filters
      data_filtered <- data_renamed %>%
        filter(
          !is.na(date),
          !is.na(as.Date(date, format = "%Y-%m-%d")),
          !is.na(count_hour),
          as.numeric(count_hour) >= 0,
          as.numeric(count_hour) <= 23,
          !is.na(up),
          as.numeric(up) >= 0,
          !is.na(down),
          as.numeric(down) >= 0
        ) %>%
        mutate(
          date = as.Date(date),
          count_hour = as.numeric(count_hour),
          duration_minutes = as.numeric(duration_minutes),
          up = as.numeric(up),
          down = as.numeric(down),
          net_up = as.numeric(net_up),
          salmon_per_hour = as.numeric(salmon_per_hour),
          sheet_name = sheet
        )
      
      all_data[[sheet]] <- data_filtered
      
    }, error = function(e) {
      warning("Error processing sheet ", sheet, ": ", e$message)
    })
  }
  
  # Combine all sheets
  if (length(all_data) > 0) {
    combined_data <- bind_rows(all_data, .id = "sheet_name")
    
    # Save combined data
    output_path <- get_file_path("silver", "didson_processed", 
                                 paste0("didson_all_sheets_", run_id, ".csv"))
    
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    write.csv(combined_data, output_path, row.names = FALSE)
    
    cat("Combined data saved to:", output_path, "\n")
    cat("Total rows processed:", nrow(combined_data), "\n")
    
    return(combined_data)
  } else {
    warning("No data was successfully processed")
    return(NULL)
  }
}

# Main execution function to test the function in interactive mode (not run in production)
if (interactive()) {
  # Example usage
  input_folder <- "prototype_data"
  run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  result <- process_all_didson_sheets(input_folder, run_id)
}
