# Qualark Pipeline Setup Guide

This guide explains how to set up the Qualark pipeline for production use with PostgreSQL database, email notifications, and Azure DevOps CI/CD.

## Current Status: Production Ready

The pipeline is production-ready with comprehensive functionality. All features can be enabled using flip switches when credentials are available.

## Prerequisites

- R 4.0+ installed
- PostgreSQL database (for production)
- SMTP email server (for notifications)
- SharePoint site (for file backup)
- Azure DevOps project (for CI/CD)

## Quick Start Testing

For comprehensive testing procedures, see **[TESTING_GUIDE.md](TESTING_GUIDE.md)**.

```r
# Basic functionality test
source("r/setup.R")
source("r/main.R")
results <- run_all_pipelines()
```

## Production Setup Steps

### Step 1: Database Setup
1. Install PostgreSQL
2. Create database: `qualark_db`
3. Run schema: `sql/qualarkspeciescomp_proto_schema.sql`
4. Update `r/config/connections.R` with credentials
5. Enable database operations:
   ```r
   source("r/data_flows/sql_integration.R")
   enable_database_operations()
   ```

### Step 2: Email Notifications
1. Configure SMTP settings in `r/config/connections.R`
2. Set environment variables for credentials
3. Enable email operations:
   ```r
   source("r/utils/email_notifications.R")
   enable_email_operations()
   ```

### Step 3: SharePoint Integration
1. Set up SharePoint site and get site ID
2. Generate access token for Microsoft Graph API
3. Configure SharePoint settings in `r/config/connections.R`
4. Enable SharePoint operations:
   ```r
   source("r/data_flows/sharepoint_integration.R")
   enable_sharepoint_operations()
   ```

### Step 4: Azure DevOps CI/CD
1. Create Azure DevOps project
2. Import repository
3. Configure variable groups for LxD deployment
4. Set up self-hosted agent on LxD
5. See `azure-devops/README.md` for detailed instructions

### Step 5: LxD Cron Jobs
1. Configure cron jobs on LxD for data processing
2. Set up log monitoring
3. Test complete workflow

## Troubleshooting

### Logs and Reports
- **Validation**: `data/silver/validation/validation_results_*.json`
- **Reports**: `data/silver/reports/pipeline_summary_*.json`

## Next Steps

1. **Test Basic Functionality**: See [TESTING_GUIDE.md](TESTING_GUIDE.md)
2. **Configure Production**: Follow setup steps above
3. **Deploy to LxD**: Set up Azure DevOps CI/CD
4. **Monitor Operations**: Set up cron jobs and monitoring

For project status and progress tracking, see [TODO_LIST.md](TODO_LIST.md).
