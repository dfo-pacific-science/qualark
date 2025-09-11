# Qualark Data Processing Pipeline

This project takes DIDSON Sonar files and test fishing species count data and processes them for storage and analysis.

Data are collected in the field by Fraser Interior Area Stock Assessment Biologists. Those data are submitted to this data system through a secure upload page hosted on an R Shiny Server in a Linux Desktop (LxD) container. 1) When the files are uploaded, they should trigger a series of events including uploading raw data copies to SharePoint (done use Microsoft365 R package), 2) Parsing the excel files into seperate .csv files into a temp forlder on our LxD for version control purposes; 3) Data quality and validation checks; 4) Transformation to the database schema; 5) Upsert to the Postgres DB.

Comprehensive testing and notifications For any errors that occur during the proces..

This project converts functionality originally developed in Azure Data Factory (ADF) JSON scripts and Logic Apps to open-source R scripts and Azure DevOps pipelines, enabling us to escape Azure dependencies while maintaining the same functionality.

## Project Structure

```
qualark/
├── r/                                    # R scripts (replaces ADF)
│   ├── config/
│   │   └── connections.R                 # Database and storage connections
│   ├── data_flows/                       # Data processing scripts
│   │   ├── process_didson_data_corrected.R
│   │   ├── process_testfishing_data_corrected.R
│   │   ├── sql_integration.R             # Database operations
│   │   └── sharepoint_integration.R     # SharePoint uploads
│   ├── utils/                            # Utility functions
│   │   ├── email_notifications.R        # Enhanced email system
│   │   ├── error_handling.R             # Error management
│   │   ├── pipeline_status.R            # Status tracking
│   │   └── database_backup.R            # Backup procedures
│   ├── parse_excel_to_csv.R             # Excel to CSV conversion utility
│   ├── setup.R                          # Package installation and setup
│   └── main.R                           # Main orchestration script
├── data/                                # Data storage (replaces Azure Data Lake)
│   ├── bronze/                          # Raw data layers 
│   │   └── Prototype/                   # Sample data files
│   ├── csv_parsed/                      # Parsed CSV files (version controlled)
│   │   ├── lookup_data/                 # Lookup tables as CSV
│   │   └── main_data/                   # Main data files as CSV
│   ├── silver/                          # Processed data layer
│   │   ├── processed_from_csv/          # Latest processed data
│   │   ├── lookups_from_csv/            # Processed lookup tables
│   │   ├── reports/                     # Pipeline summary reports
│   │   └── validation/                  # Data quality validation results
│   └── gold/                            # Analytics-ready data (future)
├── prototype_data/                      # Original Excel files
│   ├── lookup/                          # Lookup Excel files
│   ├── Qualark_2023_DIDSON_Counts.xlsx
│   └── Qualark_2023_Test_Fishing_and_Sampling.xlsx
├── sql/                                 # Database schema files
│   ├── qualarkspeciescomp_proto_schema.sql
│   └── insert_lookup_info.sql
├── docs/                                # Documentation
├── qualark-demo.Rproj                   # R project file
├── requirements.txt                     # R package requirements
├── README.md                            # This file
├── SETUP_GUIDE.md                       # Setup instructions
├── TESTING_GUIDE.md                     # Comprehensive testing guide
└── TODO_LIST.md                         # Project progress tracking
```

## Features

### ✅ **Current Capabilities**
- **Excel File Processing**: Automatically parses Excel files to CSV for version control
- **Data Validation**: Input format validation and data quality checks
- **Modular Processing**: Independent data flows for DIDSON and Test Fishing data
- **Lookup Integration**: Automatic lookup table processing and joining
- **Error Handling**: Comprehensive error logging and recovery
- **Local Development**: Works without database or email dependencies
- **Database Integration**: Complete PostgreSQL integration with flip switches
- **SharePoint Integration**: Automatic upload of raw files for provenance
- **Enhanced Notifications**: Comprehensive email notification system
- **Pipeline Status Management**: Real-time status tracking and reporting
- **Database Backup**: Automated backup and recovery procedures
- **Azure DevOps Integration**: Complete CI/CD pipeline configuration

### 🔄 **Data Flow**
1. **Excel Files Uploaded through Web Page** → **CSV Parsing** → **SharePoint Uploa/Backup** → **Data Validation** → **Processing** → **Silver Layer**
2. **Lookup Tables** → **CSV Parsing** → **Database Integration** → **Data Joining**
3. **Quality Validation** → **Database Insertion** → **Backup Creation** → **Notification** → **Summary Generation**

## Quick Start

### Prerequisites
- R 4.0+ with required packages (see `requirements.txt`)
- Excel files in `prototype_data/` directory

### Installation
```r
# Install required packages
source("r/setup.R")

# Or install manually
install.packages(c("here", "logging", "dplyr", "readxl", "readr", "tidyr", "DBI", "odbc", "lubridate", "mailR", "httr", "jsonlite", "RMySQL", "RSQLite", "RPostgres"))
```

### Basic Usage

#### Run All Pipelines
```r
source("r/main.R")
results <- run_all_pipelines()
```

#### Run Individual Pipelines
```r
# Test Fishing pipeline
result <- run_pipeline("testfishing")

# DIDSON pipeline
result <- run_pipeline("didson")

# Parse Excel files only
result <- run_pipeline("parse")

# Validate input format
result <- run_pipeline("validate")
```

#### Command Line Usage
```bash
# Run all pipelines
Rscript r/main.R

# Run specific pipeline
Rscript r/main.R testfishing
Rscript r/main.R didson
Rscript r/main.R parse
Rscript r/main.R validate
Rscript r/main.R data_quality
```

## Data Processing

### Test Fishing Data
- **Input**: `prototype_data/Qualark_2023_Test_Fishing_and_Sampling.xlsx`
- **Processing**: Detailed Catch sheet → Drifts + Fish Samples
- **Output**: 
  - `data/silver/processed_from_csv/drifts_processed_[timestamp].csv`
  - `data/silver/processed_from_csv/fish_samples_processed_[timestamp].csv`

### DIDSON Data
- **Input**: `prototype_data/Qualark_2023_DIDSON_Counts.xlsx`
- **Processing**: Multiple sheets → Consolidated DIDSON data
- **Output**: `data/silver/processed_from_csv/didson_processed_[timestamp].csv`

### Lookup Tables
- **Input**: `prototype_data/lookup/*.xlsx`
- **Processing**: Excel → CSV → Integration
- **Output**: `data/silver/lookups_from_csv/*.csv`

## Configuration

### Flip Switches for Production Readiness

The pipeline includes flip switches to enable/disable production features:

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

### Database Configuration
Edit `r/config/connections.R` to configure database connections:

```r
# PostgreSQL configuration (for production)
db_config <- list(
  driver = "PostgreSQL",
  server = "localhost",
  database = "qualark_db",
  port = 5432,
  username = "your_username",
  password = Sys.getenv("DB_PASSWORD")
)
```

### Email Configuration
Configure email notifications in `r/config/connections.R`:

```r
email_config <- list(
  smtp_server = "smtp.gmail.com",
  port = 587,
  username = "your_email@gmail.com",
  password = Sys.getenv("EMAIL_PASSWORD"),
  from = "your_email@gmail.com",
  to = c("recipient1@example.com", "recipient2@example.com")
)
```

### SharePoint Configuration
Configure SharePoint integration in `r/config/connections.R`:

```r
sharepoint_config <- list(
  site_id = Sys.getenv("SHAREPOINT_SITE_ID"),
  token = Sys.getenv("SHAREPOINT_TOKEN"),
  base_url = "https://graph.microsoft.com/v1.0/sites"
)
```

## Testing

### Step-by-Step Testing Guide

1. **Setup Environment**
   ```r
   source("r/setup.R")
   ```

2. **Parse Excel Files**
   ```r
   source("r/main.R")
   result <- run_pipeline("parse")
   ```

3. **Validate Input Format**
   ```r
   result <- run_pipeline("validate")
   ```

4. **Run Test Fishing Pipeline**
   ```r
   result <- run_pipeline("testfishing")
   ```

5. **Run DIDSON Pipeline**
   ```r
   result <- run_pipeline("didson")
   ```

6. **Validate Data Quality**
   ```r
   result <- run_pipeline("data_quality")
   ```

7. **Run All Pipelines**
   ```r
   results <- run_all_pipelines()
   ```

### Expected Outputs
- CSV files in `data/csv_parsed/`
- Processed data in `data/silver/processed_from_csv/`
- Validation reports in `data/silver/validation/`
- Summary reports in `data/silver/reports/`

## Production Setup

### PostgreSQL Database
1. Install PostgreSQL on your system
2. Create database: `qualark_db`
3. Run schema: `sql/qualarkspeciescomp_proto_schema.sql`
4. Update `r/config/connections.R` with database credentials

### Email Notifications
1. Configure SMTP settings in `r/config/connections.R`
2. Set environment variables for credentials
3. Test email functionality

### Azure DevOps (Recommended)
1. Set up Azure DevOps project and import repository
2. Configure variable groups for database and email credentials
3. Set up service connections for PostgreSQL and SMTP
4. Configure pipeline triggers and schedules
5. See `azure-devops/README.md` for detailed setup instructions

### GitHub Actions (Alternative)
1. Set up repository secrets for database and email credentials
2. Enable GitHub Actions workflows
3. Configure file monitoring and scheduled runs

## Troubleshooting

### Common Issues

1. **Excel Parsing Errors**
   - Check file paths in `prototype_data/`
   - Verify Excel file format and structure
   - Review parsing logs

2. **Data Validation Failures**
   - Check column names and data types
   - Verify lookup table structure
   - Review validation reports

3. **Database Connection Issues**
   - Verify database credentials
   - Check network connectivity
   - Review connection configuration

### Logs and Reports
- **Logs**: Check R console output and log files
- **Validation**: `data/silver/validation/validation_results_*.json`
- **Reports**: `data/silver/reports/pipeline_summary_*.json`

## Project Status

### ✅ **Completed**
- [x] Excel file parsing and CSV conversion
- [x] Data validation and quality checks
- [x] Modular data processing pipelines
- [x] Error handling and recovery
- [x] Comprehensive testing suite
- [x] Documentation and guides
- [x] Local development environment
- [x] Complete SQL database integration with flip switches
- [x] SharePoint integration for raw file storage
- [x] Enhanced email notification system
- [x] Pipeline status management and reporting
- [x] Database backup and recovery procedures
- [x] Azure DevOps pipeline configuration
- [x] Production-ready flip switches

### 🔄 **Ready for Production**
- [ ] Configure database credentials and enable database operations
- [ ] Configure email credentials and enable email notifications
- [ ] Configure SharePoint credentials and enable SharePoint operations
- [ ] Set up Azure DevOps project and configure pipelines
- [ ] Test complete production workflow

### 📋 **Future Enhancements**
- [ ] Data visualization dashboard
- [ ] Advanced analytics and reporting
- [ ] API endpoints for data access
- [ ] Mobile application for field data collection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:
1. Check the troubleshooting section
2. Review the logs and reports
3. Create an issue in the repository
4. Contact the development team