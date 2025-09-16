# Parse Excel Files to CSV (Medallion Architecture)
# This script converts Excel files from staging to bronze layer (CSV format)
# Staging -> Bronze -> Silver -> Gold (SQL Database)

library(here)
library(readxl)
library(readr)
library(dplyr)

cat("Parsing Excel files to CSV format...\n")
cat("====================================\n\n")

# Function to safely read Excel file and convert to CSV
parse_excel_to_csv <- function(excel_file, output_dir) {
  
  cat("Processing:", basename(excel_file), "\n")
  
  # Get file info
  file_info <- file.info(excel_file)
  cat("  File size:", round(file_info$size / 1024, 2), "KB\n")
  
  # Get sheet names
  sheet_names <- excel_sheets(excel_file)
  cat("  Sheets found:", paste(sheet_names, collapse = ", "), "\n")
  
  # Create output directory
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Process each sheet
  for (sheet_name in sheet_names) {
    cat("  Processing sheet:", sheet_name, "\n")
    
    # Read the sheet
    tryCatch({
      # Read with different approaches to handle various formats
      sheet_data <- read_excel(excel_file, sheet = sheet_name, col_names = FALSE)
      
      cat("    Raw data dimensions:", nrow(sheet_data), "x", ncol(sheet_data), "\n")
      
      # Show first few rows to understand structure
      cat("    First 5 rows:\n")
      print(head(sheet_data, 5))
      
      # Try to identify header row by looking for common column names
      header_candidates <- c("Date", "Drift", "Location", "Start Time", "End Time", "Duration", "Mesh Size")
      header_row <- NULL
      
      for (i in seq_len(min(10, nrow(sheet_data)))) {
        row_data <- as.character(sheet_data[i, ])
        if (any(header_candidates %in% row_data, na.rm = TRUE)) {
          header_row <- i
          cat("    Found potential header row:", i, "\n")
          cat("    Header values:", paste(row_data[!is.na(row_data)], collapse = ", "), "\n")
          break
        }
      }
      
      # Create different versions of the data
      base_name <- tools::file_path_sans_ext(basename(excel_file))
      safe_sheet_name <- gsub("[^A-Za-z0-9_-]", "_", sheet_name)
      
      # Version 1: Raw data (no header processing)
      raw_output <- file.path(output_dir, paste0(base_name, "_", safe_sheet_name, "_raw.csv"))
      write.csv(sheet_data, raw_output, row.names = FALSE)
      cat("    Saved raw data to:", basename(raw_output), "\n")
      
      # Version 2: With header row (if found)
      if (!is.null(header_row)) {
        header_data <- sheet_data[header_row:nrow(sheet_data), ]
        names(header_data) <- as.character(sheet_data[header_row, ])
        
        # Clean up column names
        names(header_data) <- gsub("[^A-Za-z0-9_.]", "_", names(header_data))
        names(header_data) <- gsub("^_+|_+$", "", names(header_data))
        names(header_data) <- gsub("_+", "_", names(header_data))
        
        header_output <- file.path(output_dir, paste0(base_name, "_", safe_sheet_name, "_with_headers.csv"))
        write.csv(header_data, header_output, row.names = FALSE)
        cat("    Saved data with headers to:", basename(header_output), "\n")
        
        # Show the processed data structure
        cat("    Processed data dimensions:", nrow(header_data), "x", ncol(header_data), "\n")
        cat("    Column names:", paste(names(header_data), collapse = ", "), "\n")
      }
      
      # Version 3: Skip first few rows (common Excel pattern)
      if (nrow(sheet_data) > 3) {
        skip_data <- sheet_data[4:nrow(sheet_data), ]
        names(skip_data) <- as.character(sheet_data[3, ])
        
        # Clean up column names
        names(skip_data) <- gsub("[^A-Za-z0-9_.]", "_", names(skip_data))
        names(skip_data) <- gsub("^_+|_+$", "", names(skip_data))
        names(skip_data) <- gsub("_+", "_", names(skip_data))
        
        skip_output <- file.path(output_dir, paste0(base_name, "_", safe_sheet_name, "_skip3.csv"))
        write.csv(skip_data, skip_output, row.names = FALSE)
        cat("    Saved data (skip 3 rows) to:", basename(skip_output), "\n")
      }
      
    }, error = function(e) {
      cat("    Error processing sheet:", e$message, "\n")
    })
    
    cat("\n")
  }
}

# Parse main data files from staging folder (Medallion Architecture)
cat("1. Parsing main data files from staging folder...\n")
staging_dir <- "data/staging"
if (!dir.exists(staging_dir)) {
  cat("Staging directory not found, creating it...\n")
  dir.create(staging_dir, recursive = TRUE, showWarnings = FALSE)
}

main_files <- list.files(staging_dir, pattern = "\\.xlsx$", full.names = TRUE)
main_files <- main_files[!grepl("lookup", main_files)]

if (length(main_files) == 0) {
  cat("No Excel files found in staging folder. Checking prototype_data as fallback...\n")
  main_files <- list.files("prototype_data", pattern = "\\.xlsx$", full.names = TRUE)
  main_files <- main_files[!grepl("lookup", main_files)]
}

for (file in main_files) {
  output_dir <- "data/bronze/main_data"
  parse_excel_to_csv(file, output_dir)
}

# Parse lookup files from staging folder
cat("2. Parsing lookup files from staging folder...\n")
lookup_files <- list.files(file.path(staging_dir, "lookup"), pattern = "\\.xlsx$", full.names = TRUE)

if (length(lookup_files) == 0) {
  cat("No lookup files found in staging/lookup. Checking prototype_data/lookup as fallback...\n")
  lookup_files <- list.files("prototype_data/lookup", pattern = "\\.xlsx$", full.names = TRUE)
}

for (file in lookup_files) {
  output_dir <- "data/bronze/lookup_data"
  parse_excel_to_csv(file, output_dir)
}

cat("3. Creating data structure summary...\n")

# Create a summary of all parsed files
summary_data <- data.frame(
  file = character(),
  sheet = character(),
  rows = integer(),
  cols = integer(),
  has_headers = logical(),
  stringsAsFactors = FALSE
)

# Analyze all generated CSV files (Bronze layer)
csv_files <- list.files("data/bronze", pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)

for (csv_file in csv_files) {
  tryCatch({
    data <- read.csv(csv_file, stringsAsFactors = FALSE)
    
    # Extract file info
    relative_path <- gsub("data/bronze/", "", csv_file)
    file_parts <- strsplit(relative_path, "/")[[1]]
    file_name <- file_parts[length(file_parts)]
    
    # Check if this looks like it has headers
    has_headers <- any(grepl("Date|Drift|Location|Start|End|Duration|Mesh", names(data), ignore.case = TRUE))
    
    summary_data <- rbind(summary_data, data.frame(
      file = file_name,
      sheet = gsub("\\.csv$", "", file_name),
      rows = nrow(data),
      cols = ncol(data),
      has_headers = has_headers,
      stringsAsFactors = FALSE
    ))
    
  }, error = function(e) {
    cat("Error analyzing", csv_file, ":", e$message, "\n")
  })
}

# Save summary
write.csv(summary_data, "data/bronze/data_structure_summary.csv", row.names = FALSE)

cat("Summary saved to: data/bronze/data_structure_summary.csv\n")
cat("Files parsed:", nrow(summary_data), "\n\n")

# Show summary
cat("Data Structure Summary:\n")
print(summary_data)

cat("\n=== PARSING COMPLETE ===\n")
cat("All Excel files have been converted to CSV format (Bronze layer).\n")
cat("Check the 'data/bronze' directory to see the actual data structure.\n")
cat("Use the summary file to understand which files have proper headers.\n")
