# Process Test Fishing Data (Corrected with Actual Structure)
# Uses the actual column names from the parsed CSV files

library(dplyr)
library(readr)
library(tidyr)
library(here)

source(here("r", "config", "connections.R"))

# Function to load lookup tables from CSV files
load_lookup_tables_from_csv <- function() {
  
  lookups <- list()
  
  # Load locations lookup
  locations_file <- "data/csv_parsed/lookup_data/DriftLocation_Sheet1_raw.csv"
  if (file.exists(locations_file)) {
    lookups$locations <- read_csv(locations_file, show_col_types = FALSE, skip = 1)
    names(lookups$locations) <- c("LocationID", "LocationName")
  }
  
  # Load mesh sizes lookup
  mesh_file <- "data/csv_parsed/lookup_data/MeshSizes_MeshSizes_raw.csv"
  if (file.exists(mesh_file)) {
    lookups$mesh_sizes <- read_csv(mesh_file, show_col_types = FALSE, skip = 1)
    names(lookups$mesh_sizes) <- c("MeshId", "MeshSize")
  }
  
  # Load species lookup
  species_file <- "data/csv_parsed/lookup_data/Species_Species_raw.csv"
  if (file.exists(species_file)) {
    lookups$species <- read_csv(species_file, show_col_types = FALSE, skip = 1)
    names(lookups$species) <- c("SpeciesID", "SpeciesCode", "Species")
  }
  
  # Load life history types lookup
  life_history_file <- "data/csv_parsed/lookup_data/LifeHistoryTypes_LifeHistoryTypes_raw.csv"
  if (file.exists(life_history_file)) {
    lookups$life_history <- read_csv(life_history_file, show_col_types = FALSE, skip = 1)
    names(lookups$life_history) <- c("LifeHistoryTypeID", "LHType", "LHCode")
  }
  
  # Load marked fish types lookup
  marked_fish_file <- "data/csv_parsed/lookup_data/MarkedFishType_MarkedFishType_raw.csv"
  if (file.exists(marked_fish_file)) {
    lookups$marked_fish <- read_csv(marked_fish_file, show_col_types = FALSE, skip = 1)
    names(lookups$marked_fish) <- c("MarkedFishTypeId", "MarkedFishTypeCode", "MarkedFishType")
  }
  
  return(lookups)
}

# Function to process test fishing data from CSV
process_testfishing_data_from_csv <- function(run_id = "") {
  
  cat("Processing test fishing data from CSV...\n")
  
  # Load the actual CSV file
  testfishing_file <- "data/csv_parsed/main_data/Qualark_2023_Test_Fishing_and_Sampling_Detailed_Catch_with_headers.csv"
  
  if (!file.exists(testfishing_file)) {
    stop("Test fishing CSV file not found: ", testfishing_file)
  }
  
  # Read the data
  raw_data <- read_csv(testfishing_file, show_col_types = FALSE)
  
  cat("  Loaded raw data:", nrow(raw_data), "rows\n")
  
  # Remove the header row (row 1 contains the actual column names)
  data <- raw_data[-1, ]
  
  # Convert data types
  data <- data %>%
    mutate(
      Date = as.Date(as.numeric(Date), origin = "1899-12-30"),
      Drift_Number = as.numeric(Drift_Number),
      Mesh_Size = as.numeric(Mesh_Size)
    ) %>%
    rename(
      drift_date = Date,
      drift_number = Drift_Number,
      location = Location,
      drift_start_time = Start_Time,
      drift_end_time = End_Time,
      duration = Duration,
      mesh_size = Mesh_Size
    )
  
  # Filter valid rows
  valid_data <- data %>%
    filter(
      !is.na(drift_date),
      !is.na(drift_number),
      drift_number > 0,
      !is.na(mesh_size),
      mesh_size >= 0,
      !is.na(location),
      location != ""
    )
  
  cat("  Valid data rows:", nrow(valid_data), "\n")
  
  # Load lookup tables
  lookups <- load_lookup_tables_from_csv()
  
  # Join with lookups
  data_with_lookups <- valid_data %>%
    left_join(lookups$locations, by = c("location" = "LocationName")) %>%
    left_join(lookups$mesh_sizes, by = c("mesh_size" = "MeshSize"))
  
  # Save processed data
  output_path <- get_file_path("silver", "processed_from_csv", 
                              paste0("testfishing_processed_", run_id, ".csv"))
  
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(data_with_lookups, output_path, row.names = FALSE)
  
  cat("  Saved processed data to:", output_path, "\n")
  
  return(data_with_lookups)
}

# Function to process drifts data from the processed test fishing data
process_drifts_from_testfishing <- function(testfishing_data, run_id = "") {
  
  cat("Processing drifts data from test fishing data...\n")
  
  # Create drifts data
  drifts_data <- testfishing_data %>%
    select(
      drift_date,
      drift_number,
      location_id = LocationID,
      drift_start_time,
      drift_end_time,
      duration,
      MeshId,
      location,
      comments = Comments
    ) %>%
    distinct() %>%
    mutate(
      created_at = Sys.time(),
      updated_at = Sys.time(),
      updated_by = "csv_processor"
    )
  
  cat("  Created", nrow(drifts_data), "drift records\n")
  
  # Save drifts data
  output_path <- get_file_path("silver", "processed_from_csv", 
                              paste0("drifts_processed_", run_id, ".csv"))
  
  write.csv(drifts_data, output_path, row.names = FALSE)
  
  cat("  Saved drifts data to:", output_path, "\n")
  
  return(drifts_data)
}

# Function to process fish samples data from the processed test fishing data
process_fish_samples_from_testfishing <- function(testfishing_data, drifts_data, run_id = "") {
  
  cat("Processing fish samples data from test fishing data...\n")
  
  # Load lookup tables
  lookups <- load_lookup_tables_from_csv()
  
  # Create drift ID mapping
  drift_mapping <- drifts_data %>%
    select(drift_date, drift_number, location, MeshId) %>%
    mutate(drift_id = row_number())
  
  # Identify catch columns
  catch_columns <- names(testfishing_data)[grepl("(Retained|Released)", names(testfishing_data), ignore.case = TRUE)]
  
  cat("  Found", length(catch_columns), "catch columns\n")
  
  # Process catch data
  fish_samples <- data.frame()
  
  for (col in catch_columns) {
      # Get non-zero catches
      catches <- testfishing_data %>%
        select(drift_date, drift_number, location, MeshId, catch_count = !!col) %>%
        filter(!is.na(catch_count), catch_count > 0) %>%
        mutate(retention_type = ifelse(grepl("Retained", col), "retained", "released"))
    
    if (nrow(catches) > 0) {
      # Parse species and life history from column name
      if (grepl("Adult.*Sockeye", col)) {
        catches$species_key <- "Sockeye"
        catches$life_history_key <- "Adult"
      } else if (grepl("Jack.*Sockeye", col)) {
        catches$species_key <- "Sockeye"
        catches$life_history_key <- "Jack"
      } else if (grepl("Adult.*Chinook", col)) {
        catches$species_key <- "Chinook"
        catches$life_history_key <- "Adult"
      } else if (grepl("Jack.*Chinook", col)) {
        catches$species_key <- "Chinook"
        catches$life_history_key <- "Jack"
      } else if (grepl("Coho", col)) {
        catches$species_key <- "Coho"
        catches$life_history_key <- "Adult"
      } else if (grepl("Pink", col)) {
        catches$species_key <- "Pink"
        catches$life_history_key <- "Adult"
      } else if (grepl("Chum", col)) {
        catches$species_key <- "Chum"
        catches$life_history_key <- "Adult"
      } else if (grepl("Steelhead", col)) {
        catches$species_key <- "Steelhead"
        catches$life_history_key <- "Adult"
      } else {
        catches$species_key <- "Unknown"
        catches$life_history_key <- "Adult"
      }
      
      # Join with drift mapping
      catches_with_drift_id <- catches %>%
        left_join(drift_mapping, by = c("drift_date", "drift_number", "location", "MeshId")) %>%
        filter(!is.na(drift_id))
      
      # Join with species lookup
      catches_with_species <- catches_with_drift_id %>%
        left_join(lookups$species, by = c("species_key" = "Species")) %>%
        left_join(lookups$life_history, by = c("life_history_key" = "LHType"))
      
      # Add to fish samples
      fish_samples <- rbind(fish_samples, catches_with_species)
    }
  }
  
  # Prepare final fish samples data
  final_fish_samples <- fish_samples %>%
    select(
      drift_id,
      species_id = SpeciesID,
      life_history_type_id = LifeHistoryTypeID,
      catch_count,
      retention_type
    ) %>%
    mutate(
      marked_fish_type_id = 1,  # Default to unmarked
      created_at = Sys.time()
    ) %>%
    filter(!is.na(drift_id), !is.na(species_id))
  
  cat("  Created", nrow(final_fish_samples), "fish sample records\n")
  
  # Save fish samples data
  output_path <- get_file_path("silver", "processed_from_csv", 
                              paste0("fish_samples_processed_", run_id, ".csv"))
  
  write.csv(final_fish_samples, output_path, row.names = FALSE)
  
  cat("  Saved fish samples data to:", output_path, "\n")
  
  return(final_fish_samples)
}

# Main function to process all test fishing data
process_all_testfishing_data <- function() {
  
  cat("Processing all test fishing data from CSV files...\n")
  cat("================================================\n\n")
  
  run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Step 1: Process test fishing data
  testfishing_data <- process_testfishing_data_from_csv(run_id)
  
  # Step 2: Process drifts data
  drifts_data <- process_drifts_from_testfishing(testfishing_data, run_id)
  
  # Step 3: Process fish samples data
  fish_samples_data <- process_fish_samples_from_testfishing(testfishing_data, drifts_data, run_id)
  
  # Summary
  cat("\n=== PROCESSING SUMMARY ===\n")
  cat("Test fishing data processed:", nrow(testfishing_data), "rows\n")
  cat("Drifts created:", nrow(drifts_data), "records\n")
  cat("Fish samples created:", nrow(fish_samples_data), "records\n")
  cat("Run ID:", run_id, "\n")
  
  return(list(
    testfishing_data = testfishing_data,
    drifts_data = drifts_data,
    fish_samples_data = fish_samples_data,
    run_id = run_id
  ))
}

# Test function
if (interactive()) {
  results <- process_all_testfishing_data()
}
