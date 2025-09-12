# Qualark Pipeline Testing Guide

This guide provides step-by-step instructions to test the Qualark pipeline system.

## Prerequisites

- R 4.0+ installed
- Excel files in `prototype_data/` directory
- All required R packages installed

## Quick Test

```r
# Basic functionality test
source("r/setup.R")
source("r/main.R")
results <- run_all_pipelines()
```

## Comprehensive Testing

### Step 1: Environment Setup
```r
# Install required packages
source("r/setup.R")

# Verify package installation
library(here)
library(dplyr)
library(readr)
library(readxl)
library(tidyr)
library(lubridate)
library(logging)
```

### Step 2: Verify Excel Files
```r
# Check Excel files exist
excel_files <- list.files("prototype_data", pattern = "\\.xlsx$", recursive = TRUE)
print("Excel files found:")
print(excel_files)
```

### Step 3: Test Excel Parsing
```r
# Load main pipeline
source("r/main.R")

# Parse Excel files
result <- run_pipeline("parse")
if (result$status == "Success") {
  cat("✓ Excel files parsed successfully\n")
} else {
  cat("✗ Excel parsing failed:", result$message, "\n")
}
```

### Step 4: Test Input Validation
```r
# Validate input format
result <- run_pipeline("validate")
cat("Validation Results:\n")
for (item in names(result)) {
  if (result[[item]] == "Found" || result[[item]] == "Valid") {
    cat("✓", item, ":", result[[item]], "\n")
  } else {
    cat("✗", item, ":", result[[item]], "\n")
  }
}
```

### Step 5: Test Test Fishing Pipeline
```r
# Run test fishing pipeline
result <- run_pipeline("testfishing")
if (result$status == "Success") {
  cat("✓ Test fishing pipeline completed successfully\n")
} else {
  cat("✗ Test fishing pipeline failed:", result$message, "\n")
}
```

### Step 6: Test DIDSON Pipeline
```r
# Run DIDSON pipeline
result <- run_pipeline("didson")
if (result$status == "Success") {
  cat("✓ DIDSON pipeline completed successfully\n")
} else {
  cat("✗ DIDSON pipeline failed:", result$message, "\n")
}
```

### Step 7: Test Complete Pipeline
```r
# Run all pipelines
results <- run_all_pipelines()
cat("Pipeline Summary:\n")
cat("  - Test Fishing:", results$testfishing$status, "\n")
cat("  - DIDSON:", results$didson$status, "\n")
cat("  - Total Successful:", results$summary$successful_runs, "\n")
cat("  - Total Failed:", results$summary$failed_runs, "\n")
```

### Step 8: Test Data Quality Validation
```r
# Run data quality validation
result <- run_pipeline("data_quality")
cat("Data Quality Validation Results:\n")
if (length(result) > 0) {
  for (file in names(result)) {
    if (result[[file]]$status == "Pass") {
      cat("✓", file, "passed validation\n")
    } else {
      cat("✗", file, "failed validation:", result[[file]]$message, "\n")
    }
  }
}
```

## Advanced Testing

### Error Handling Test
```r
# Test with missing Excel files
file.rename("prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx", 
            "prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx.backup")

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

### Performance Test
```r
# Test processing time
start_time <- Sys.time()
result <- run_pipeline("testfishing")
end_time <- Sys.time()

processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
cat("Processing time:", round(processing_time, 2), "seconds\n")
```

## Test Summary

### Expected Results
After completing all tests, you should have:
- ✓ All packages loaded successfully
- ✓ Excel files parsed to CSV
- ✓ Input validation passed
- ✓ Test fishing pipeline completed
- ✓ DIDSON pipeline completed (or handled gracefully)
- ✓ Complete pipeline test passed
- ✓ Data quality validation completed
- ✓ Error handling works correctly
- ✓ Performance acceptable

### Troubleshooting
If any test fails:
1. Check error messages in the console output
2. Review log files for detailed error information
3. Verify file paths and permissions
4. Check data format and structure

### Next Steps
After successful testing:
1. **Set up production**: See [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. **Deploy to LxD**: Set up Azure DevOps CI/CD
3. **Monitor operations**: Set up cron jobs and monitoring

### Command Line Testing
```bash
# Test specific pipeline
Rscript r/main.R testfishing
Rscript r/main.R didson
Rscript r/main.R parse
Rscript r/main.R validate

# Test complete pipeline
Rscript r/main.R
```