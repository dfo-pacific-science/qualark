# Azure DevOps Setup for Qualark Pipeline

This directory contains Azure DevOps pipeline configurations and setup instructions for the Qualark Data Processing Pipeline.

## Overview

The Azure DevOps pipeline provides CI/CD deployment functionality to deploy code to the LxD container. Data processing is handled by cron jobs on the LxD instance, not by Azure DevOps compute resources.

## Pipeline Structure

### Main Pipeline: `qualark-data-pipeline.yml`

The main pipeline consists of 2 stages:

1. **Build** - Validates code and creates deployment artifacts
2. **Deploy** - Deploys code to LxD container and sets up cron jobs

## Setup Instructions

### 1. Create Azure DevOps Project

1. Go to [Azure DevOps](https://dev.azure.com)
2. Create a new project named "Qualark CI/CD"
3. Import this repository into the project

### 2. Configure Variable Groups

Create a variable group named `qualark-pipeline-variables` with the following variables:

#### LxD Deployment Variables
- `LXD_HOST` - LxD container hostname or IP
- `LXD_USER` - LxD username for deployment
- `LXD_SSH_KEY` - SSH private key for LxD access (mark as secret)

#### Optional Variables (for notifications)
- `EMAIL_SMTP_SERVER` - SMTP server for deployment notifications
- `EMAIL_PORT` - SMTP port (default: 587)
- `EMAIL_USERNAME` - Email username
- `EMAIL_PASSWORD` - Email password (mark as secret)
- `EMAIL_FROM` - From email address
- `EMAIL_TO` - Comma-separated list of recipient email addresses

### 3. Set Up Self-Hosted Agent on LxD

#### Install Azure DevOps Agent
1. Download the agent from Azure DevOps
2. Install on LxD container
3. Configure agent to run as service
4. Add agent to the "LxD-SelfHosted" pool

#### Required Software on LxD
- R 4.3.2 or later
- Git
- SSH access configured
- Cron service running

### 4. Configure Pipeline

#### Create Pipeline
1. Go to Pipelines > Create Pipeline
2. Select "Azure Repos Git"
3. Choose your repository
4. Select "Existing Azure Pipelines YAML file"
5. Choose `azure-devops/pipelines/qualark-data-pipeline.yml`

#### Configure Triggers
The pipeline triggers on:
- Code changes to `r/*` directory
- Changes to `azure-devops/*` files
- Changes to documentation files
- Pull requests to main branch

### 5. Set Up Cron Jobs on LxD

After deployment, configure cron jobs on LxD for data processing:

#### Daily Processing (6 AM)
```bash
0 6 * * * cd /opt/qualark && Rscript r/main.R >> /var/log/qualark/qualark.log 2>&1
```

#### Hourly Processing (if needed)
```bash
0 * * * * cd /opt/qualark && Rscript r/main.R >> /var/log/qualark/qualark.log 2>&1
```

#### Manual Processing
```bash
cd /opt/qualark
Rscript r/main.R
```

## Pipeline Stages Details

### Stage 1: Build
- **Purpose**: Validates code and creates deployment artifacts
- **Duration**: ~3-5 minutes
- **Dependencies**: None
- **Outputs**: Code artifacts for deployment

### Stage 2: Deploy
- **Purpose**: Deploys code to LxD container and sets up cron jobs
- **Duration**: ~2-3 minutes
- **Dependencies**: Build stage
- **Outputs**: Deployed code on LxD, cron job templates

## Monitoring and Alerts

### Pipeline Monitoring
1. Go to Pipelines > Pipelines
2. Select your pipeline
3. View run history and logs
4. Set up notifications for deployment failures

### Deployment Notifications
- Deployment success/failure notifications
- Code validation results
- LxD deployment status

### LxD Monitoring
- Monitor cron job execution logs in `/var/log/qualark/`
- Check R process status on LxD
- Monitor data processing results

## Troubleshooting

### Common Issues

#### LxD Connection Issues
- Verify SSH connectivity to LxD
- Check SSH key configuration
- Ensure LxD agent is running

#### Deployment Failures
- Check LxD disk space
- Verify file permissions
- Review deployment logs

#### R Package Installation Issues
- Check R installation on LxD
- Verify package repository access
- Review package installation logs

### Debugging Steps

1. **Check Pipeline Logs**
   - Go to pipeline run
   - Click on failed stage
   - Review detailed logs

2. **Test LxD Connectivity**
   - SSH to LxD manually
   - Check agent status
   - Verify R installation

3. **Check Deployment**
   - Verify code deployment in `/opt/qualark`
   - Test R script execution
   - Check cron job configuration

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
