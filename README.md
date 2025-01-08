
# Jenkins Logs Storage in Azure Blob

## Overview

This project provides a cost-efficient solution for storing Jenkins logs in Azure Blob Storage, replacing the high-cost ELK stack. Azure Blob Storage is leveraged to store Jenkins logs with lifecycle management enabled, ensuring automated archiving or deletion of older logs. A shell script is developed to automate the upload of Jenkins logs to Blob Storage, scheduled to run daily via cron jobs.

---

## Features

- **Cost Optimization**: Replaces the ELK stack for log storage with Azure Blob Storage, significantly reducing costs.
- **Automation**: Automates daily uploads of Jenkins logs using a shell script.
- **Lifecycle Management**: Enables lifecycle policies to archive or delete logs after a defined period.
- **Scalability**: Utilizes Azure Blob Storage, which scales to meet storage needs.

---

## Prerequisites

1. **Jenkins Server**:
   - A running Jenkins instance with logs stored in `/var/lib/jenkins` or a custom directory.

2. **Azure Account**:
   - An active Azure subscription.

3. **Azure CLI**:
   - Installed Azure CLI for interacting with Azure services.
   - Installation:
     ```bash
     sudo apt install azure-cli -y
     ```

4. **Azure Storage Account**:
   - A storage account to store the logs.

5. **Blob Storage Container**:
   - A container created within the storage account.

6. **Access Permissions**:
   - Proper authentication with Azure CLI using `az login` or a service principal.

---

## Project Steps

### Step 1: Set Up Azure Blob Storage

1. **Create a Storage Account**:
   ```bash
   az storage account create \
       --name <storage_account_name> \
       --resource-group <resource_group_name> \
       --location <location> \
       --sku Standard_LRS


2. **Create a Blob Storage Container**:
 ```bash
az storage container create \
    --name <container_name> \
    --account-name <storage_account_name>


Enable Lifecycle Management: Configure a policy to archive or delete logs older than 30 days:

bash
Copy code
az storage account management-policy create \
    --account-name <storage_account_name> \
    --policy '{
        "rules": [
            {
                "enabled": true,
                "name": "move-to-archive",
                "type": "Lifecycle",
                "definition": {
                    "actions": {
                        "baseBlob": {
                            "tierToArchive": {
                                "daysAfterModificationGreaterThan": 30
                            }
                        }
                    },
                    "filters": {
                        "blobTypes": ["blockBlob"]
                    }
                }
            }
        ]
    }'
Step 2: Shell Script for Uploading Logs
A shell script is developed to automate the daily upload of Jenkins logs to Azure Blob Storage.

Shell Script:

bash
Copy code
#!/bin/bash

# Variables
JENKINS_HOME="/var/lib/jenkins"
STORAGE_ACCOUNT_NAME="your_storage_account_name"
CONTAINER_NAME="your-container-name"
DATE=$(date +%Y-%m-%d)

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it to proceed."
    exit 1
fi

# Iterate through all job directories
for job_dir in "$JENKINS_HOME/jobs/"*/; do
    job_name=$(basename "$job_dir")
    
    # Iterate through build directories for the job
    for build_dir in "$job_dir/builds/"*/; do
        build_number=$(basename "$build_dir")
        log_file="$build_dir/log"

        if [ -f "$log_file" ] && [ "$(date -r "$log_file" +%Y-%m-%d)" == "$DATE" ]; then
            az storage blob upload \
                --account-name "$STORAGE_ACCOUNT_NAME" \
                --container-name "$CONTAINER_NAME" \
                --file "$log_file" \
                --name "$job_name-$build_number.log" \
                --only-show-errors
            
            if [ $? -eq 0 ]; then
                echo "Uploaded: $job_name/$build_number to $CONTAINER_NAME/$job_name-$build_number.log"
            else
                echo "Failed to upload: $job_name/$build_number"
            fi
        fi
    done
done
Step 3: Schedule the Script
Create a Cron Job:

Schedule the script to run daily at midnight:

bash
Copy code
crontab -e
Add the following line:

bash
Copy code
0 0 * * * /path/to/jenkins-log-upload.sh >> /var/log/jenkins-log-upload.log 2>&1
Verify Cron Job Execution:

Check the log file for script execution details:


tail -f /var/log/jenkins-log-upload.log
Testing
Manual Execution:
Run the script manually to ensure proper uploads:


bash /path/to/jenkins-log-upload.sh
Validation:
Verify that the logs are uploaded to the Blob Storage container.
Confirm lifecycle management rules are applied.
Outcome
Cost Reduction:

Significantly reduced storage costs by replacing the ELK stack with Azure Blob Storage.
Automation:

Automated daily log uploads and lifecycle management.
Scalability:

Leveraged Azure Blob Storage’s scalability to handle growing log data.
Future Improvements
Compression:

Add log compression to reduce storage costs further.
Monitoring:

Integrate Azure Monitor or Log Analytics for querying and analyzing logs.
Notifications:

Add email or Slack notifications for upload success or failures.
