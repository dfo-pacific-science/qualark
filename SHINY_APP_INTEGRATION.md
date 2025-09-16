# Shiny App Integration Guide

## Overview

Your Shiny app needs to integrate with the Qualark data processing pipeline. Everything runs in the same LxD container, so integration is straightforward.

## Required Tasks

### 1. File Upload to Staging
- Upload Excel files to `data/staging/` directory (permanent archival to be backed up somewhere at some point)
- Validate file types (.xlsx, .xls) and reasonable file sizes
- Create run-specific subdirectories for organization

### 2. Trigger Pipeline Processing
- Call the main pipeline function to process uploaded files on successful upload
- Display processing status and results to users
- Handle errors gracefully (notify users, email developers?)

### 3. Display File Status
- Show uploaded files with metadata (size, date, status)
- Display processing history and results
- Allow users to see what's been processed

## Integration Options



### Option A: Direct Function Calls (Simplest)
```r
# Source the pipeline functions directly
source("path/to/qualark/r/main.R")

# Move files to staging
file.copy(uploaded_files, "data/staging/", overwrite = TRUE)

# Run pipeline
results <- run_all_pipelines()
```

### Option B: Use Helper Functions
```r
# Create simple helper functions for common tasks
move_to_staging <- function(files) {
  # Move files to data/staging/ with run ID
}

run_processing <- function() {
  # Call the main pipeline
}
```

### Option C: API Interface (Future-proof)
```r
# Use API interface functions (if you want to keep things separate)
source("path/to/qualark/r/api/shiny_interface.R")
validation <- validate_uploaded_files(file_paths)
```

## Data Flow

1. **Upload**: User uploads Excel files
2. **Staging**: Files stored in `data/staging/` (permanent archival)
3. **Processing**: Pipeline processes through medallion architecture:
   - Staging → Bronze (parsed CSV)
   - Bronze → Silver (processed data)  
   - Silver → Gold (SQL database)
4. **Status**: Display results to user

## Key Pipeline Functions

- `run_all_pipelines()` - Runs the complete processing pipeline
- `parse_excel_files_with_validation()` - Parses Excel files to CSV
- `run_testfishing_pipeline_corrected()` - Processes test fishing data
- `run_didson_pipeline_corrected()` - Processes DIDSON data

## Discussion Points

### Repository Structure
- **Keep separate**: Your Shiny app stays in its own repo
- **Merge together**: Move Shiny app into this repo for simpler deployment?
- **Hybrid**: Keep separate but share common functions?

### User Experience
- How much validation feedback do users need?
- Should users be able to delete uploaded files? Or update/replace them? For eg. if they realized they uploaded something in error.
- Do we want real-time processing status or just final results?

### Excel File Validation
- How much QC should we do at the upload stage?

### Submission Metadata
- What metadata do we need to capture?
  - Depends on whether we let them edit/replace I guess?

### Error Handling
- How should we handle processing failures?
- Should users get detailed error messages or simple status?
- Do we need retry mechanisms?

### File Management
- How long should we keep files in bronze/silver?
- Do we need file versioning or just overwrite?
- Should we archive old processing runs?

## Next Steps

1. **Choose integration approach** (A, B, or C above)
2. **Implement file upload to staging**
3. **Add pipeline processing trigger**
4. **Test with sample Excel files**
5. **Discuss the points above**

Let me know what you think and we can work through the details together!
