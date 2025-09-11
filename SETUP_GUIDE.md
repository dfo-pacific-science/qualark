# Qualark Pipeline Setup Guide

This guide explains how to set up the Qualark pipeline for production use with PostgreSQL database and email notifications.

## Current Status: Production Ready

The pipeline is now production-ready with comprehensive functionality including database integration, SharePoint uploads, enhanced notifications, and Azure DevOps integration. All features can be enabled using flip switches when credentials are available.

## Quick Start Testing

### 1. Initial Setup
```r
# Install required packages
source("r/setup.R")

# Verify installation
library(here)
library(dplyr)
library(readr)
library(readxl)
```

### 2. Test Excel Parsing
```r
# Parse Excel files to CSV
source("r/main.R")
result <- run_pipeline("parse")
print(result)
```

### 3. Validate Input Format
```r
# Check if all required files are present and valid
result <- run_pipeline("validate")
print(result)
```

### 4. Run Test Fishing Pipeline
```r
# Process test fishing data
result <- run_pipeline("testfishing")
print(result)
```

### 5. Run DIDSON Pipeline
```r
# Process DIDSON data
result <- run_pipeline("didson")
print(result)
```

### 6. Run All Pipelines
```r
# Run complete pipeline
results <- run_all_pipelines()
print(results)
```

## Step-by-Step Testing Guide

### Phase 1: Basic Functionality (No External Dependencies)

1. **Setup Environment**
   ```r
   # Install packages
   source("r/setup.R")
   
   # Check package installation
   library(here)
   library(dplyr)
   library(readr)
   library(readxl)
   library(tidyr)
   library(lubridate)
   library(logging)
   ```

2. **Verify Excel Files**
   ```r
   # Check if Excel files exist
   list.files("prototype_data", pattern = "\\.xlsx$", recursive = TRUE)
   
   # Should show:
   # - prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx
   # - prototype_data/Qualark_2023_DIDSON_Counts.xlsx
   # - prototype_data/lookup/*.xlsx
   ```

3. **Parse Excel Files**
   ```r
   source("r/main.R")
   result <- run_pipeline("parse")
   
   # Check results
   if (result$status == "Success") {
     cat("✓ Excel files parsed successfully\n")
   } else {
     cat("✗ Excel parsing failed:", result$message, "\n")
   }
   ```

4. **Validate Input Format**
   ```r
   result <- run_pipeline("validate")
   
   # Check validation results
   for (item in names(result)) {
     if (result[[item]] == "Found" || result[[item]] == "Valid") {
       cat("✓", item, ":", result[[item]], "\n")
     } else {
       cat("✗", item, ":", result[[item]], "\n")
     }
   }
   ```

5. **Test Test Fishing Pipeline**
   ```r
   result <- run_pipeline("testfishing")
   
   # Check results
   if (result$status == "Success") {
     cat("✓ Test fishing pipeline completed successfully\n")
     cat("  - Drifts created:", nrow(result$data$drifts_data), "\n")
     cat("  - Fish samples created:", nrow(result$data$fish_samples_data), "\n")
   } else {
     cat("✗ Test fishing pipeline failed:", result$message, "\n")
   }
   ```

6. **Test DIDSON Pipeline**
   ```r
   result <- run_pipeline("didson")
   
   # Check results
   if (result$status == "Success") {
     cat("✓ DIDSON pipeline completed successfully\n")
   } else {
     cat("✗ DIDSON pipeline failed:", result$message, "\n")
   }
   ```

7. **Run Complete Pipeline**
   ```r
   results <- run_all_pipelines()
   
   # Check overall results
   cat("Pipeline Summary:\n")
   cat("  - Test Fishing:", results$testfishing$status, "\n")
   cat("  - DIDSON:", results$didson$status, "\n")
   cat("  - Total Successful:", results$summary$successful_runs, "\n")
   cat("  - Total Failed:", results$summary$failed_runs, "\n")
   ```

8. **Validate Data Quality**
   ```r
   result <- run_pipeline("data_quality")
   
   # Check validation results
   cat("Data Quality Validation:\n")
   for (file in names(result)) {
     if (result[[file]]$status == "Pass") {
       cat("✓", file, "passed validation\n")
     } else {
       cat("✗", file, "failed validation:", result[[file]]$message, "\n")
     }
   }
   ```

### Phase 2: Database Integration (PostgreSQL)

1. **Install PostgreSQL**
   ```bash
   # Windows (using Chocolatey)
   choco install postgresql
   
   # Or download from: https://www.postgresql.org/download/
   ```

2. **Create Database**
   ```sql
   -- Connect to PostgreSQL
   psql -U postgres
   
   -- Create database
   CREATE DATABASE qualark_db;
   
   -- Create user
   CREATE USER qualark_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE qualark_db TO qualark_user;
   ```

3. **Run Database Schema**
   ```bash
   # Run the schema file
   psql -U qualark_user -d qualark_db -f sql/qualarkspeciescomp_proto_schema.sql
   ```

4. **Update Database Configuration**
   ```r
   # Edit r/config/connections.R
   db_config <- list(
     driver = "PostgreSQL",
     server = "localhost",
     database = "qualark_db",
     port = 5432,
     username = "qualark_user",
     password = "your_password"
   )
   ```

5. **Test Database Connection**
   ```r
   # Test connection
   source("r/config/connections.R")
   conn <- get_db_connection()
   
   if (!is.null(conn)) {
     cat("✓ Database connection successful\n")
     DBI::dbDisconnect(conn)
   } else {
     cat("✗ Database connection failed\n")
   }
   ```

### Phase 3: Email Notifications

1. **Configure Email Settings**
   ```r
   # Edit r/config/connections.R
   email_config <- list(
     smtp_server = "smtp.gmail.com",
     port = 587,
     username = "your_email@gmail.com",
     password = Sys.getenv("EMAIL_PASSWORD"),
     from = "your_email@gmail.com",
     to = c("recipient1@example.com", "recipient2@example.com")
   )
   ```

2. **Set Environment Variables**
   ```r
   # Set email password
   Sys.setenv(EMAIL_PASSWORD = "your_app_password")
   
   # Set database password
   Sys.setenv(DB_PASSWORD = "your_database_password")
   ```

3. **Test Email Functionality**
   ```r
   # Test email sending
   source("r/utils/email_notifications.R")
   result <- send_pipeline_notification("Test", "This is a test email")
   
   if (result$status == "Success") {
     cat("✓ Email notification sent successfully\n")
   } else {
     cat("✗ Email notification failed:", result$message, "\n")
   }
   ```

## Production Setup

### Step 1: Enable Production Features

The pipeline includes flip switches to enable production features when ready:

```r
# Enable database operations (when ready)
source("r/data_flows/sql_integration.R")
enable_database_operations()

# Enable email notifications (when ready)
source("r/utils/email_notifications.R")
enable_email_operations()

# Enable SharePoint operations (when ready)
source("r/data_flows/sharepoint_integration.R")
enable_sharepoint_operations()

# Enable backup operations (when ready)
source("r/utils/database_backup.R")
enable_backup_operations()
```

### Step 2: PostgreSQL Database Setup
1. Install PostgreSQL on your system
2. Create database: `qualark_db`
3. Run schema: `sql/qualarkspeciescomp_proto_schema.sql`
4. Update `r/config/connections.R` with database credentials
5. Test database connection

### Step 3: Email Notifications Setup
1. Configure SMTP settings in `r/config/connections.R`
2. Set environment variables for credentials
3. Test email functionality
4. Enable email operations

### Step 4: SharePoint Integration Setup
1. Set up SharePoint site and get site ID
2. Generate access token for Microsoft Graph API
3. Configure SharePoint settings in `r/config/connections.R`
4. Test SharePoint upload functionality
5. Enable SharePoint operations

### Step 5: Azure DevOps Setup (Recommended)
1. Create Azure DevOps project
2. Import repository
3. Configure variable groups for credentials
4. Set up service connections
5. Configure pipeline triggers
6. See `azure-devops/README.md` for detailed instructions

### Step 6: Database Backup Setup
1. Create backup directory: `data/backups/database`
2. Configure backup retention policies
3. Test backup and restore procedures
4. Enable backup operations

### Step 7: Production Testing
1. Test complete pipeline with all features enabled
2. Verify database operations
3. Test email notifications
4. Verify SharePoint uploads
5. Test backup procedures
6. Monitor pipeline status and reports

## Production Deployment

### 1. Environment Setup
- Set up production PostgreSQL database
- Configure email SMTP settings
- Set up file monitoring (Azure DevOps or GitHub Actions)
- Configure logging and monitoring

### 2. Code Updates for Production
- Update `r/config/connections.R` with production credentials
- Set up environment variables for sensitive data
- Configure error handling and logging
- Set up data backup procedures

### 3. Monitoring and Maintenance
- Set up automated testing
- Configure data quality monitoring
- Set up error alerting
- Plan data archiving strategy

## Troubleshooting

### Common Issues

1. **Excel Parsing Errors**
   - Check file paths and permissions
   - Verify Excel file format
   - Review parsing logs

2. **Database Connection Issues**
   - Verify PostgreSQL is running
   - Check credentials and permissions
   - Test network connectivity

3. **Email Notification Issues**
   - Verify SMTP settings
   - Check authentication credentials
   - Test with different email providers

4. **Data Validation Failures**
   - Review validation rules
   - Check data format and structure
   - Verify lookup table integrity

### Logs and Debugging

- **Console Output**: Check R console for error messages
- **Log Files**: Review logging output for detailed information
- **Validation Reports**: Check `data/silver/validation/` for validation results
- **Summary Reports**: Check `data/silver/reports/` for pipeline summaries

## Next Steps

1. **Complete Phase 1 Testing**: Ensure all basic functionality works
2. **Set up PostgreSQL**: Follow Phase 2 instructions
3. **Configure Email**: Follow Phase 3 instructions
4. **Production Deployment**: Follow production deployment guide
5. **Monitoring Setup**: Implement monitoring and alerting

## Support

For issues or questions:
1. Check this guide first
2. Review error logs and reports
3. Test individual components
4. Create an issue in the repository
5. Contact the development team