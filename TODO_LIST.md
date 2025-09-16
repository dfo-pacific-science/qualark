# Qualark Pipeline TODO List

## ✅ Completed Items

### Core Functionality
- [x] Excel file parsing to CSV for version control
- [x] Test fishing data processing pipeline
- [x] DIDSON data processing pipeline
- [x] Lookup table integration
- [x] Input format validation
- [x] Data quality validation
- [x] Error handling and logging
- [x] Repository cleanup and organization

### Documentation
- [x] Updated README.md with current structure
- [x] Updated SETUP_GUIDE.md with new workflow
- [x] Created TESTING_GUIDE.md with step-by-step instructions
- [x] Created TODO_LIST.md for progress tracking
- [x] Cleaned up unnecessary documentation files

### Code Organization
- [x] Integrated Excel parsing into main pipeline
- [x] Updated main.R to use corrected processing
- [x] Removed old and unnecessary files
- [x] Streamlined data flow structure
- [x] Created version-controlled CSV files
- [x] Cleaned up old pipeline files
- [x] Removed duplicate data directories
- [x] Consolidated data structure

### Testing and Validation
- [x] Complete Phase 1 testing (Basic Functionality)
- [x] Complete Phase 2 testing (Advanced Testing)
- [x] Complete Phase 3 testing (Performance Testing)
- [x] Complete Phase 4 testing (Integration Testing)

## 🔄 In Progress

- [ ] Update schema based on Sai's updates
- [ ] Incorporate length and aris text file concatenation into DevOps pipeline

## 📋 Production Deployment Tasks

### Configuration Setup
- [ ] Configure database credentials and enable operations
- [ ] Configure email credentials and enable notifications
- [ ] Integrate Shiny app using integration guide
- [ ] Set up Azure DevOps project and configure CI/CD pipelines
- [ ] Set up self-hosted agent on LxD container
- [ ] Configure cron jobs on LxD for data processing
- [ ] Test complete medallion architecture workflow

### Optional Enhancements
- [ ] Set up monitoring dashboard
- [ ] Add API endpoints for data access

## 🚀 Immediate Next Steps

### Production Configuration
1. **Configure Database** - Set up PostgreSQL and enable operations (after Sai's updates)
2. **Configure Email** - Set up SMTP and enable notifications (Waiting on IT)
3. **Integrate Shiny App** - Coordinate with Curtis on integration guide 

### Azure DevOps Setup
1. **Create Project** - Import repository and configure variables (Wu)
2. **Set up Agent** - Install self-hosted agent on LxD (Wu)
3. **Configure Pipelines** - Set up CI/CD deployment (Wu)

### Production Testing
1. **End-to-End Testing** - Test complete workflow (Curtis)


