# Qualark Pipeline Testing Guide

This guide provides step-by-step instructions to test the entire Qualark pipeline system.

## Prerequisites

- R 4.0+ installed
- Excel files in `prototype_data/` directory
- All required R packages installed

## Phase 1: Basic Functionality Testing

### Step 1: Environment Setup
```r
# 1.1 Install required packages
source("r/setup.R")

# 1.2 Verify package installation
library(here)
library(dplyr)
library(readr)
library(readxl)
library(tidyr)
library(lubridate)
library(logging)

# 1.3 Check if all packages loaded successfully
cat("✓ All required packages loaded successfully\n")
```

### Step 2: Verify Excel Files
```r
# 2.1 Check Excel files exist
excel_files <- list.files("prototype_data", pattern = "\\.xlsx$", recursive = TRUE)
print("Excel files found:")
print(excel_files)

# 2.2 Verify required files

required_files <- c(
  "prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx",
  "prototype_data/Qualark_2023_DIDSON_Counts.xlsx",
  "prototype_data/lookup/DriftLocation.xlsx",
  "prototype_data/lookup/Species.xlsx",
  "prototype_data/lookup/MeshSizes.xlsx"
)

for (file in required_files) {
  if (file.exists(file)) {
    cat("✓", file, "found\n")
  } else {
    cat("✗", file, "missing\n")
  }
}
```

### Step 3: Test Excel Parsing
```r
# 3.1 Load main pipeline
source("r/main.R")

# 3.2 Parse Excel files
cat("Parsing Excel files to CSV...\n")
result <- run_pipeline("parse")

# 3.3 Check parsing results
if (result$status == "Success") {
  cat("✓ Excel files parsed successfully\n")
} else {
  cat("✗ Excel parsing failed:", result$message, "\n")
  stop("Excel parsing failed")
}

# 3.4 Verify CSV files created
csv_files <- list.files("data/csv_parsed", pattern = "\\.csv$", recursive = TRUE)
cat("CSV files created:", length(csv_files), "\n")
```

### Step 4: Test Input Validation
```r
# 4.1 Validate input format
cat("Validating input data format...\n")
result <- run_pipeline("validate")

# 4.2 Check validation results
cat("Validation Results:\n")
for (item in names(result)) {
  if (result[[item]] == "Found" || result[[item]] == "Valid") {
    cat("✓", item, ":", result[[item]], "\n")
  } else {
    cat("✗", item, ":", result[[item]], "\n")
  }
}

# 4.3 Check if validation passed
validation_passed <- all(grepl("Found|Valid", result))
if (validation_passed) {
  cat("✓ Input validation passed\n")
} else {
  cat("⚠ Input validation had issues, but continuing...\n")
}
```

### Step 5: Test Test Fishing Pipeline
```r
# 5.1 Run test fishing pipeline
cat("Running Test Fishing pipeline...\n")
result <- run_pipeline("testfishing")

# 5.2 Check results
if (result$status == "Success") {
  cat("✓ Test fishing pipeline completed successfully\n")
  cat("  - Test fishing data rows:", nrow(result$data$testfishing_data), "\n")
  cat("  - Drifts created:", nrow(result$data$drifts_data), "\n")
  cat("  - Fish samples created:", nrow(result$data$fish_samples_data), "\n")
} else {
  cat("✗ Test fishing pipeline failed:", result$message, "\n")
  stop("Test fishing pipeline failed")
}

# 5.3 Verify output files
testfishing_files <- list.files("data/silver/processed_from_csv", pattern = "testfishing.*\\.csv$")
drifts_files <- list.files("data/silver/processed_from_csv", pattern = "drifts.*\\.csv$")
fish_samples_files <- list.files("data/silver/processed_from_csv", pattern = "fish_samples.*\\.csv$")

cat("Output files created:\n")
cat("  - Test fishing files:", length(testfishing_files), "\n")
cat("  - Drifts files:", length(drifts_files), "\n")
cat("  - Fish samples files:", length(fish_samples_files), "\n")
```

### Step 6: Test DIDSON Pipeline
```r
# 6.1 Run DIDSON pipeline
cat("Running DIDSON pipeline...\n")
result <- run_pipeline("didson")

# 6.2 Check results
if (result$status == "Success") {
  cat("✓ DIDSON pipeline completed successfully\n")
} else {
  cat("✗ DIDSON pipeline failed:", result$message, "\n")
  # Note: DIDSON pipeline might fail if no DIDSON data is available
  cat("⚠ Continuing with other tests...\n")
}
```

### Step 7: Test Complete Pipeline
```r
# 7.1 Run all pipelines
cat("Running complete pipeline...\n")
results <- run_all_pipelines()

# 7.2 Check overall results
cat("Pipeline Summary:\n")
cat("  - Test Fishing:", results$testfishing$status, "\n")
cat("  - DIDSON:", results$didson$status, "\n")
cat("  - Total Successful:", results$summary$successful_runs, "\n")
cat("  - Total Failed:", results$summary$failed_runs, "\n")

# 7.3 Check if at least test fishing succeeded
if (results$testfishing$status == "Success") {
  cat("✓ Complete pipeline test passed\n")
} else {
  cat("✗ Complete pipeline test failed\n")
  stop("Complete pipeline test failed")
}
```

### Step 8: Test Data Quality Validation
```r
# 8.1 Run data quality validation
cat("Running data quality validation...\n")
result <- run_pipeline("data_quality")

# 8.2 Check validation results
cat("Data Quality Validation Results:\n")
if (length(result) > 0) {
  for (file in names(result)) {
    if (result[[file]]$status == "Pass") {
      cat("✓", file, "passed validation\n")
    } else {
      cat("✗", file, "failed validation:", result[[file]]$message, "\n")
    }
  }
} else {
  cat("⚠ No data quality validation results found\n")
}
```

## Phase 2: Advanced Testing

### Step 9: Test Error Handling
```r
# 9.1 Test with missing Excel files
cat("Testing error handling with missing files...\n")

# Temporarily rename Excel files
file.rename("prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx", 
            "prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx.backup")

# Try to run pipeline
result <- run_pipeline("testfishing")
if (result$status == "Error") {
  cat("✓ Error handling works correctly\n")
} else {
  cat("✗ Error handling failed\n")
}

# Restore files
file.rename("prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx.backup", 
            "prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx")
```

### Step 10: Test Data Processing Logic
```r
# 10.1 Test data processing with actual data
cat("Testing data processing logic...\n")

# Load processed data
testfishing_file <- list.files("data/silver/processed_from_csv", 
                               pattern = "testfishing.*\\.csv$", 
                               full.names = TRUE)[1]

if (file.exists(testfishing_file)) {
  data <- readr::read_csv(testfishing_file, show_col_types = FALSE)
  
  # Check data structure
  cat("Data structure check:\n")
  cat("  - Rows:", nrow(data), "\n")
  cat("  - Columns:", ncol(data), "\n")
  cat("  - Date column type:", class(data$drift_date), "\n")
  cat("  - Drift number range:", min(data$drift_number, na.rm = TRUE), "-", 
      max(data$drift_number, na.rm = TRUE), "\n")
  
  # Check for missing values
  missing_values <- sum(is.na(data$drift_date) | is.na(data$drift_number) | is.na(data$location))
  cat("  - Missing values in key columns:", missing_values, "\n")
  
  if (missing_values == 0) {
    cat("✓ Data processing logic working correctly\n")
  } else {
    cat("⚠ Data processing has some missing values\n")
  }
} else {
  cat("✗ No processed data found for testing\n")
}
```

### Step 11: Test Lookup Integration
```r
# 11.1 Test lookup table integration
cat("Testing lookup table integration...\n")

# Check lookup files
lookup_files <- list.files("data/silver/lookups_from_csv", pattern = "\\.csv$")
cat("Lookup files available:", paste(lookup_files, collapse = ", "), "\n")

# Test species lookup
species_file <- "data/silver/lookups_from_csv/species.csv"
if (file.exists(species_file)) {
  species_data <- readr::read_csv(species_file, show_col_types = FALSE)
  cat("Species lookup:\n")
  print(species_data)
  cat("✓ Species lookup working\n")
} else {
  cat("✗ Species lookup file missing\n")
}
```

## Phase 3: Performance Testing

### Step 12: Test Performance
```r
# 12.1 Test processing time
cat("Testing processing performance...\n")

start_time <- Sys.time()
result <- run_pipeline("testfishing")
end_time <- Sys.time()

processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
cat("Processing time:", round(processing_time, 2), "seconds\n")

if (processing_time < 60) {
  cat("✓ Processing performance acceptable\n")
} else {
  cat("⚠ Processing time is slow, consider optimization\n")
}
```

### Step 13: Test Memory Usage
```r
# 13.1 Check memory usage
cat("Testing memory usage...\n")

# Get memory usage before processing
mem_before <- gc()

# Run processing
result <- run_pipeline("testfishing")

# Get memory usage after processing
mem_after <- gc()

# Calculate memory increase
mem_increase <- mem_after[2, 2] - mem_before[2, 2]
cat("Memory increase:", round(mem_increase, 2), "MB\n")

if (mem_increase < 100) {
  cat("✓ Memory usage acceptable\n")
} else {
  cat("⚠ High memory usage detected\n")
}
```

## Phase 4: Integration Testing

### Step 14: Test Complete Workflow
```r
# 14.1 Test complete workflow from Excel to processed data
cat("Testing complete workflow...\n")

# Clear previous processed data
unlink("data/silver/processed_from_csv/*", recursive = TRUE)

# Run complete pipeline
results <- run_all_pipelines()

# Check if all expected files are created
expected_files <- c(
  "testfishing_processed_",
  "drifts_processed_",
  "fish_samples_processed_"
)

created_files <- list.files("data/silver/processed_from_csv", pattern = "\\.csv$")
cat("Files created:", length(created_files), "\n")

# Check if expected files exist
for (pattern in expected_files) {
  matching_files <- grep(pattern, created_files, value = TRUE)
  if (length(matching_files) > 0) {
    cat("✓", pattern, "files created\n")
  } else {
    cat("✗", pattern, "files missing\n")
  }
}
```

### Step 15: Test Data Consistency
```r
# 15.1 Test data consistency across processing
cat("Testing data consistency...\n")

# Load test fishing data
testfishing_file <- list.files("data/silver/processed_from_csv", 
                               pattern = "testfishing.*\\.csv$", 
                               full.names = TRUE)[1]

# Load drifts data
drifts_file <- list.files("data/silver/processed_from_csv", 
                          pattern = "drifts.*\\.csv$", 
                          full.names = TRUE)[1]

if (file.exists(testfishing_file) && file.exists(drifts_file)) {
  testfishing_data <- readr::read_csv(testfishing_file, show_col_types = FALSE)
  drifts_data <- readr::read_csv(drifts_file, show_col_types = FALSE)
  
  # Check if drift counts match
  testfishing_drifts <- length(unique(paste(testfishing_data$drift_date, testfishing_data$drift_number)))
  drifts_count <- nrow(drifts_data)
  
  cat("Drift consistency check:\n")
  cat("  - Test fishing drifts:", testfishing_drifts, "\n")
  cat("  - Drifts table rows:", drifts_count, "\n")
  
  if (testfishing_drifts == drifts_count) {
    cat("✓ Data consistency check passed\n")
  } else {
    cat("✗ Data consistency check failed\n")
  }
} else {
  cat("✗ Cannot perform consistency check - files missing\n")
}
```

## Test Summary

### Expected Results
After completing all tests, you should have:

1. **✓ All packages loaded successfully**
2. **✓ Excel files parsed to CSV**
3. **✓ Input validation passed**
4. **✓ Test fishing pipeline completed**
5. **✓ DIDSON pipeline completed (or handled gracefully)**
6. **✓ Complete pipeline test passed**
7. **✓ Data quality validation completed**
8. **✓ Error handling works correctly**
9. **✓ Data processing logic working**
10. **✓ Lookup integration working**
11. **✓ Performance acceptable**
12. **✓ Memory usage acceptable**
13. **✓ Complete workflow working**
14. **✓ Data consistency maintained**

### Troubleshooting

If any test fails:

1. **Check error messages** in the console output
2. **Review log files** for detailed error information
3. **Verify file paths** and permissions
4. **Check data format** and structure
5. **Test individual components** to isolate issues

### Next Steps

After successful testing:

1. **Set up PostgreSQL database** (Phase 2 of SETUP_GUIDE.md)
2. **Configure email notifications** (Phase 3 of SETUP_GUIDE.md)
3. **Deploy to production** (Production Deployment section)
4. **Set up monitoring** and alerting

## Command Line Testing

You can also run tests from the command line:

```bash
# Test Excel parsing
Rscript r/main.R parse

# Test input validation
Rscript r/main.R validate

# Test test fishing pipeline
Rscript r/main.R testfishing

# Test DIDSON pipeline
Rscript r/main.R didson

# Test complete pipeline
Rscript r/main.R

# Test data quality
Rscript r/main.R data_quality
```

This comprehensive testing guide ensures that all components of the Qualark pipeline are working correctly before moving to production deployment.