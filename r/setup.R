# Setup script for Qualark Data Processing Pipeline
# Run this script to initialize the project

library(here)

# Create necessary directories
create_directories <- function() {
  
  cat("Creating project directories...\n")
  
  # Data directories (Medallion Architecture)
  data_dirs <- c(
    "data/staging",  # Raw Excel files from Shiny app (permanent archival)
    "data/bronze/Prototype",
    "data/bronze/error_files",
    "data/bronze/main_data",  # Parsed CSV files
    "data/bronze/lookup_data",  # Parsed lookup CSV files
    "data/silver/didson_processed",
    "data/silver/qualark_testfishing_and_sampling",
    "data/silver/processed_drifts",
    "data/silver/processed_fish_samples",
    "data/silver/lookups",
    "data/silver/error_logs",
    "data/silver/validation",
    "data/silver/reports",
    "data/gold",     # Analytics-ready data (SQL database)
    "data/backup"
  )
  
  for (dir in data_dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      cat("Created directory:", dir, "\n")
    }
  }
  
  cat("Directory creation completed.\n")
}

# Install required packages
install_packages <- function() {
  
  cat("Installing required R packages...\n")
  
  required_packages <- c(
    "dplyr", "readxl", "readr", "tidyr", "DBI", "odbc",
    "lubridate", "mailR", "httr", "jsonlite", "logging",
    "here", "DBI", "RMySQL", "RSQLite"
  )
  
  for (package in required_packages) {
    if (!require(package, character.only = TRUE)) {
      install.packages(package, repos = "https://cran.rstudio.com/")
      cat("Installed package:", package, "\n")
    } else {
      cat("Package already installed:", package, "\n")
    }
  }
  
  cat("Package installation completed.\n")
}

# Create sample configuration files
create_sample_configs <- function() {
  
  cat("Creating sample configuration files...\n")
  
  # Create .env template
  env_template <- "# Environment Variables for Qualark Pipeline
# Copy this file to .env and fill in your values

# Database Configuration
DB_PASSWORD=your_database_password
DB_USERNAME=your_database_username
DB_SERVER=your_database_server
DB_DATABASE=your_database_name

# Email Configuration
EMAIL_USERNAME=your_email@domain.com
EMAIL_PASSWORD=your_email_password
EMAIL_SMTP_SERVER=smtp.gmail.com
EMAIL_SMTP_PORT=587

# Local Storage Configuration (no external credentials needed)
# Files are stored locally in temp/ and data/ folders

# Notification URLs (if using webhooks)
NOTIFICATION_WEBHOOK_URL=https://your-webhook-url.com/notify
"
  
  if (!file.exists(".env.template")) {
    writeLines(env_template, ".env.template")
    cat("Created .env.template\n")
  }
  
  # Create sample lookup files
  create_sample_lookups()
  
  cat("Sample configuration files created.\n")
}

# Create sample lookup tables
create_sample_lookups <- function() {
  
  cat("Creating sample lookup tables...\n")
  
  # Locations lookup
  locations <- data.frame(
    LocationID = c("LOC001", "LOC002", "LOC003", "LOC004"),
    LocationName = c("Qualark Creek", "Fraser River", "Harrison River", "Chilliwack River"),
    stringsAsFactors = FALSE
  )
  
  write.csv(locations, "data/silver/lookups/locations.csv", row.names = FALSE)
  cat("Created locations lookup\n")
  
  # Mesh sizes lookup
  mesh_sizes <- data.frame(
    MeshId = c(1, 2, 3, 4, 5),
    MeshSize = c(1.5, 2.0, 2.5, 3.0, 3.5),
    stringsAsFactors = FALSE
  )
  
  write.csv(mesh_sizes, "data/silver/lookups/mesh_sizes.csv", row.names = FALSE)
  cat("Created mesh sizes lookup\n")
  
  # Species lookup
  species <- data.frame(
    SpeciesID = c(1, 2, 3, 4, 5, 6),
    SpeciesCode = c("SOC", "CHI", "COH", "PIN", "CHU", "STE"),
    Species = c("sockeye", "chinook", "coho", "pink", "chum", "steelhead"),
    stringsAsFactors = FALSE
  )
  
  write.csv(species, "data/silver/lookups/species.csv", row.names = FALSE)
  cat("Created species lookup\n")
  
  # Life history types lookup
  life_history <- data.frame(
    LifeHistoryTypeID = c("LH001", "LH002"),
    LHType = c("adult", "jack"),
    LHCode = c("AD", "JK"),
    stringsAsFactors = FALSE
  )
  
  write.csv(life_history, "data/silver/lookups/life_history_types.csv", row.names = FALSE)
  cat("Created life history types lookup\n")
  
  # Marked fish types lookup
  marked_fish <- data.frame(
    MarkedFishTypeId = c(1, 2, 3),
    MarkedFishTypeCode = c("Unm", "ADC", "UNK"),
    MarkedFishType = c("ad_p", "ad_a", "ad_unk"),
    stringsAsFactors = FALSE
  )
  
  write.csv(marked_fish, "data/silver/lookups/marked_fish_types.csv", row.names = FALSE)
  cat("Created marked fish types lookup\n")
}

# Create sample data files
create_sample_data <- function() {
  
  cat("Creating sample data files...\n")
  
  # Create sample DIDSON data
  didson_data <- data.frame(
    Date = c("2023-07-15", "2023-07-16", "2023-07-17"),
    `Count Hour` = c(8, 9, 10),
    Duration = c(60, 60, 60),
    Up = c(15, 23, 18),
    Down = c(12, 19, 14),
    `Net Up` = c(3, 4, 4),
    `Salmon/Hour` = c(0.05, 0.067, 0.067),
    Comments = c("Good visibility", "Clear water", "Slightly murky"),
    stringsAsFactors = FALSE
  )
  
  write.csv(didson_data, "data/bronze/Prototype/sample_didson_data.csv", row.names = FALSE)
  cat("Created sample DIDSON data\n")
  
  # Create sample test fishing data
  testfishing_data <- data.frame(
    drift_date = c("2023-07-15", "2023-07-16", "2023-07-17"),
    drift_number = c(1, 2, 3),
    location = c("Qualark Creek", "Fraser River", "Harrison River"),
    drift_start_time = c("08:00:00", "09:00:00", "10:00:00"),
    drift_end_time = c("09:00:00", "10:00:00", "11:00:00"),
    duration = c("01:00:00", "01:00:00", "01:00:00"),
    mesh_size = c(2.0, 2.5, 2.0),
    adult_sockeye_retained = c(5, 8, 3),
    jack_sockeye_retained = c(2, 1, 1),
    adult_chinook_retained_ad_p = c(3, 2, 4),
    adult_chinook_retained_ad_a = c(1, 0, 1),
    adult_chinook_retained_ad_unk = c(0, 1, 0),
    jack_chinook_retained_ad_p = c(1, 1, 0),
    jack_chinook_retained_ad_a = c(0, 0, 1),
    jack_chinook_retained_ad_unk = c(0, 0, 0),
    coho_retained_ad_p = c(2, 3, 1),
    coho_retained_ad_a = c(0, 1, 0),
    coho_retained_ad_unk = c(0, 0, 1),
    pink_retained = c(0, 0, 0),
    chum_retained = c(0, 0, 0),
    steelhead_retained = c(0, 0, 0),
    adult_sockeye_released = c(0, 0, 0),
    jack_sockeye_released = c(0, 0, 0),
    adult_chinook_released_ad_p = c(0, 0, 0),
    adult_chinook_released_ad_a = c(0, 0, 0),
    adult_chinook_released_ad_unk = c(0, 0, 0),
    jack_chinook_released_ad_p = c(0, 0, 0),
    jack_chinook_released_ad_a = c(0, 0, 0),
    jack_chinook_released_ad_unk = c(0, 0, 0),
    coho_released_ad_p = c(0, 0, 0),
    coho_released_ad_a = c(0, 0, 0),
    coho_released_ad_unk = c(0, 0, 0),
    pink_released = c(0, 0, 0),
    chum_released = c(0, 0, 0),
    steelhead_released = c(0, 0, 0),
    comments = c("Good catch", "Excellent visibility", "Standard conditions"),
    total_adult_chinook_retained = c(4, 3, 5),
    total_jack_chinook_retained = c(1, 1, 1),
    total_adult_chinook_released = c(0, 0, 0),
    total_jack_chinook_released = c(0, 0, 0),
    total_coho_retained = c(2, 4, 2),
    total_coho_released = c(0, 0, 0),
    stringsAsFactors = FALSE
  )
  
  write.csv(testfishing_data, "data/bronze/Prototype/sample_testfishing_data.csv", row.names = FALSE)
  cat("Created sample test fishing data\n")
}

# Main setup function
setup_project <- function() {
  
  cat("Setting up Qualark Data Processing Pipeline...\n")
  cat("============================================\n\n")
  
  # Create directories
  create_directories()
  
  # Install packages
  install_packages()
  
  # Create sample configurations
  create_sample_configs()
  
  # Create sample data
  create_sample_data()
  
  cat("\nSetup completed successfully!\n")
  cat("\nNext steps:\n")
  cat("1. Copy .env.template to .env and fill in your configuration\n")
  cat("2. Update r/config/connections.R with your database settings\n")
  cat("3. Run 'Rscript r/main.R' to test the pipeline\n")
  cat("4. Set up GitHub Actions workflows in .github/workflows/\n")
}

# Run setup if script is executed directly
if (interactive()) {
  setup_project()
}
