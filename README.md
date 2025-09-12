# Qualark Data Processing Pipeline

A production-ready data processing system for DIDSON Sonar files and test fishing species count data collected by Fraser Interior Area Stock Assessment Biologists.

## Overview

Data flows from field collection → R Shiny Server upload → SharePoint backup → CSV parsing → validation → processing → PostgreSQL database. The system uses Azure DevOps for CI/CD deployment to LxD containers where cron jobs handle data processing.

**Key Features**: Excel parsing, data validation, PostgreSQL integration, SharePoint backup, email notifications, automated testing, and production-ready flip switches.

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
1. **Code Development** → **GitHub Push** → **Azure DevOps CI/CD** → **LxD Deployment** → **Cron Job Processing**
2. **Excel Files Uploaded through Web Page** → **CSV Parsing** → **SharePoint Upload/Backup** → **Data Validation** → **Processing** → **Silver Layer**
3. **Lookup Tables** → **CSV Parsing** → **Database Integration** → **Data Joining**
4. **Quality Validation** → **Database Insertion** → **Backup Creation** → **Notification** → **Summary Generation**

## Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[SETUP_GUIDE.md](SETUP_GUIDE.md)** | Production setup and configuration | Before deploying to production |
| **[TESTING_GUIDE.md](TESTING_GUIDE.md)** | Comprehensive testing procedures | During development and before production |
| **[TODO_LIST.md](TODO_LIST.md)** | Project progress and next steps | For project management and planning |
| **[azure-devops/README.md](azure-devops/README.md)** | Azure DevOps CI/CD setup | When setting up deployment pipelines |

## Quick Start

### Prerequisites
- R 4.0+ with required packages
- Excel files in `prototype_data/` directory

### Installation
```r
# Install required packages
source("r/setup.R")
```

### Basic Usage
```r
# Run all pipelines
source("r/main.R")
results <- run_all_pipelines()

# Run specific pipeline
result <- run_pipeline("testfishing")
result <- run_pipeline("didson")
result <- run_pipeline("parse")
result <- run_pipeline("validate")
```

### Command Line
```bash
# Run all pipelines
Rscript r/main.R

# Run specific pipeline
Rscript r/main.R testfishing
Rscript r/main.R didson
Rscript r/main.R parse
Rscript r/main.R validate
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

For comprehensive testing procedures, see **[TESTING_GUIDE.md](TESTING_GUIDE.md)**.

### Quick Test
```r
# Basic functionality test
source("r/setup.R")
source("r/main.R")
results <- run_all_pipelines()
```

## Production Setup

For detailed production setup instructions, see **[SETUP_GUIDE.md](SETUP_GUIDE.md)**.

### Quick Setup Checklist
- [ ] Configure database credentials in `r/config/connections.R`
- [ ] Set up email SMTP settings
- [ ] Configure SharePoint integration
- [ ] Set up Azure DevOps CI/CD pipeline
- [ ] Configure LxD cron jobs for data processing

### Flip Switches
Enable production features when ready:
```r
# Enable database operations
source("r/data_flows/sql_integration.R")
enable_database_operations()

# Enable email notifications
source("r/utils/email_notifications.R")
enable_email_operations()

# Enable SharePoint operations
source("r/data_flows/sharepoint_integration.R")
enable_sharepoint_operations()
```

## Troubleshooting

### Common Issues
- **Excel Parsing**: Check file paths and format in `prototype_data/`
- **Database Connection**: Verify credentials in `r/config/connections.R`
- **Email Notifications**: Check SMTP settings and credentials

### Logs and Reports
- **Validation**: `data/silver/validation/validation_results_*.json`
- **Reports**: `data/silver/reports/pipeline_summary_*.json`

For project status and progress tracking, see **[TODO_LIST.md](TODO_LIST.md)**.

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