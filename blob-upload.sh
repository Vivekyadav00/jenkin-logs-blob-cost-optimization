#!/bin/bash

# Author: Vivek
# Description: Shell script to upload Jenkins log files to Azure Blob Storage

# Variables
JENKINS_HOME="/var/lib/jenkins"                  # Jenkins home directory
STORAGE_ACCOUNT_NAME="vivekjenkinslogs"         # Azure Storage Account Name
CONTAINER_NAME="jenkins-logs"                   # Blob Storage container name
DATE=$(date +%Y-%m-%d)                          # Today's date

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "ERROR: Azure CLI is not installed. Please install it to proceed."
    exit 1
fi

# Log in to Azure if not already logged in
if ! az account show &> /dev/null; then
    echo "INFO: Azure CLI is not logged in. Please log in to proceed."
    az login
fi

# Iterate through all job directories
for job_dir in "$JENKINS_HOME/jobs/"*/; do
    job_name=$(basename "$job_dir")

    # Iterate through build directories for the job
    for build_dir in "$job_dir/builds/"*/; do
        build_number=$(basename "$build_dir")
        log_file="$build_dir/log"

        # Check if log file exists and was created today
        if [ -f "$log_file" ] && [ "$(date -r "$log_file" +%Y-%m-%d)" == "$DATE" ]; then
            echo "INFO: Uploading $job_name/$build_number log to Azure Blob Storage..."
            
            # Upload log file to Azure Blob Storage
            az storage blob upload \
                --account-name "$STORAGE_ACCOUNT_NAME" \
                --container-name "$CONTAINER_NAME" \
                --file "$log_file" \
                --name "$job_name-$build_number.log" \
                --only-show-errors

            if [ $? -eq 0 ]; then
                echo "SUCCESS: Uploaded $job_name/$build_number to $CONTAINER_NAME/$job_name-$build_number.log"
            else
                echo "ERROR: Failed to upload $job_name/$build_number"
            fi
        fi
    done
done


