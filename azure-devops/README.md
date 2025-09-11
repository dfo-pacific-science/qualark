# Azure DevOps Setup for Qualark Pipeline

This directory contains Azure DevOps pipeline configurations and setup instructions for the Qualark Data Processing Pipeline.

## Overview

The Azure DevOps pipeline replaces the Azure Data Factory functionality with a more flexible, open-source approach while maintaining the same data processing capabilities.

## Pipeline Structure

### Main Pipeline: `qualark-data-pipeline.yml`

The main pipeline consists of 5 stages:

1. **Validate** - Validates input data files
2. **Process** - Processes Excel files and generates CSV outputs
3. **Database** - Inserts processed data into PostgreSQL database
4. **Notify** - Sends email notifications
5. **Backup** - Creates database backups

## Setup Instructions

### 1. Create Azure DevOps Project

1. Go to [Azure DevOps](https://dev.azure.com)
2. Create a new project named "Qualark Data Pipeline"
3. Import this repository into the project

### 2. Configure Variable Groups

Create a variable group named `qualark-pipeline-variables` with the following variables:

#### Database Variables
- `DB_HOST` - PostgreSQL server hostname
- `DB_PORT` - PostgreSQL port (default: 5432)
- `DB_NAME` - Database name
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password (mark as secret)

#### Email Variables
- `EMAIL_SMTP_SERVER` - SMTP server hostname
- `EMAIL_PORT` - SMTP port (default: 587)
- `EMAIL_USERNAME` - Email username
- `EMAIL_PASSWORD` - Email password (mark as secret)
- `EMAIL_FROM` - From email address
- `EMAIL_TO` - Comma-separated list of recipient email addresses

#### SharePoint Variables (Optional)
- `SHAREPOINT_SITE_ID` - SharePoint site ID
- `SHAREPOINT_TOKEN` - SharePoint access token (mark as secret)

### 3. Create Service Connections

#### Database Service Connection
1. Go to Project Settings > Service connections
2. Create new service connection for PostgreSQL
3. Configure connection details
4. Test the connection

#### Email Service Connection
1. Create service connection for SMTP
2. Configure SMTP settings
3. Test email sending

### 4. Configure Pipeline Triggers

#### File Upload Trigger
1. Go to Pipelines > Create Pipeline
2. Select "Azure Repos Git"
3. Choose your repository
4. Select "Existing Azure Pipelines YAML file"
5. Choose `azure-devops/pipelines/qualark-data-pipeline.yml`

#### Scheduled Trigger
1. Edit the pipeline YAML file
2. Add schedule trigger:
```yaml
schedules:
- cron: "0 6 * * *"  # Daily at 6 AM
  displayName: Daily Data Processing
  branches:
    include:
    - main
```

### 5. Configure Build Agents

#### Self-Hosted Agent (Recommended)
1. Set up a self-hosted agent on your LxD container
2. Install R and required packages
3. Configure agent to run as service
4. Add agent to the "ubuntu-latest" pool

#### Microsoft-Hosted Agent
- Uses Ubuntu 20.04
- R and packages installed during pipeline execution
- May have longer execution times

## Pipeline Stages Details

### Stage 1: Validate
- **Purpose**: Validates input data files before processing
- **Duration**: ~2-3 minutes
- **Dependencies**: None
- **Outputs**: Validation results

### Stage 2: Process
- **Purpose**: Processes Excel files and generates CSV outputs
- **Duration**: ~5-10 minutes
- **Dependencies**: Validate stage
- **Outputs**: Processed CSV files

### Stage 3: Database
- **Purpose**: Inserts processed data into PostgreSQL database
- **Duration**: ~3-5 minutes
- **Dependencies**: Process stage
- **Outputs**: Database records

### Stage 4: Notify
- **Purpose**: Sends email notifications about pipeline status
- **Duration**: ~1-2 minutes
- **Dependencies**: Process and Database stages
- **Outputs**: Email notifications

### Stage 5: Backup
- **Purpose**: Creates database backups
- **Duration**: ~2-3 minutes
- **Dependencies**: Database stage
- **Outputs**: Database backup files

## Monitoring and Alerts

### Pipeline Monitoring
1. Go to Pipelines > Pipelines
2. Select your pipeline
3. View run history and logs
4. Set up notifications for failures

### Email Notifications
- Success notifications sent to configured email addresses
- Error notifications include detailed error information
- Daily summary reports available

### Database Monitoring
- Database connection status monitored
- Backup success/failure notifications
- Data quality validation results

## Troubleshooting

### Common Issues

#### R Package Installation Failures
- Check internet connectivity
- Verify package repository URLs
- Consider using package caching

#### Database Connection Issues
- Verify database credentials
- Check network connectivity
- Ensure database server is running

#### Email Notification Failures
- Verify SMTP settings
- Check email credentials
- Test email sending manually

### Debugging Steps

1. **Check Pipeline Logs**
   - Go to pipeline run
   - Click on failed stage
   - Review detailed logs

2. **Test Individual Components**
   - Run validation stage only
   - Test database connection separately
   - Verify email configuration

3. **Check Variable Values**
   - Ensure all required variables are set
   - Verify secret variables are properly configured
   - Test variable substitution

## Security Considerations

### Secret Management
- Use Azure Key Vault for sensitive data
- Mark passwords as secret variables
- Rotate credentials regularly

### Network Security
- Use private endpoints for database connections
- Configure firewall rules appropriately
- Monitor network traffic

### Access Control
- Limit pipeline access to authorized users
- Use service principals for automation
- Audit pipeline executions

## Performance Optimization

### Parallel Execution
- Run independent stages in parallel
- Use multiple agents for large datasets
- Optimize R code for performance

### Caching
- Cache R packages between runs
- Cache processed data when possible
- Use incremental processing

### Resource Management
- Monitor memory usage
- Optimize database queries
- Clean up temporary files

## Backup and Recovery

### Database Backups
- Automated daily backups
- Retention policy for backup files
- Test backup restoration procedures

### Code Backups
- Git repository serves as code backup
- Tag releases for version control
- Maintain deployment documentation

### Data Backups
- Processed data stored in multiple locations
- SharePoint integration for file storage
- Regular data integrity checks

## Maintenance

### Regular Tasks
- Update R packages monthly
- Review and rotate credentials
- Monitor pipeline performance
- Update documentation

### Monthly Reviews
- Analyze pipeline execution metrics
- Review error logs and patterns
- Update security configurations
- Plan capacity requirements

## Support

### Documentation
- This README file
- Pipeline YAML comments
- R code documentation
- Database schema documentation

### Contact Information
- Development team: [team-email]
- Database administrator: [dba-email]
- System administrator: [sysadmin-email]

### Escalation Process
1. Check pipeline logs and documentation
2. Contact development team
3. Escalate to system administrator if needed
4. Create support ticket for critical issues
