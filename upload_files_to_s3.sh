#!/bin/sh
echo "REPOSITORY: terraform-aws-jenkins"
echo "SCRIPT: upload_files_to_s3.sh <s3prefix> <region>"
echo "EXECUTING: upload_files_to_s3.sh"

s3_prefix=$1
if [ -z "$s3_prefix" ]; then
    echo "An s3prefix must be provided! Failing out."
fi

target_aws_region=$2
if [ -z "$target_aws_region" ]; then
    target_aws_region=us-east-1
    echo "No region was passed in, using \"${target_aws_region}\" as the default"
fi

env_name = $3
if [ -z "$env_name" ]; then
    env_name=TestJenkins01
    echo "No environment name was passed in, using \"${env_name}\" as the default"
fi

# Use this file to upload the init.sh file to S3
echo "Uploading Jenkins Files to S3 - Used to replace things on jenkins during boot"
aws s3 cp --recursive ./files/ s3://${s3_prefix}-jenkins-files-${target_aws_region}/

# Use this file to upload the init.sh file to S3
echo "Uploading Jenkins Terraform state to S3 "
aws s3 cp  ./.terraform/terraform.tfstate s3://${s3_prefix}-terraform-states-${target_aws_region}/${env_name}/
# Remane uploaded terraform state from 'terraform.tfstate' to 'jenkins.tfstate'
aws s3 mv s3://${s3_prefix}-terraform-states-${target_aws_region}/${env_name}/terraform.tfstate  s3://${s3_prefix}-terraform-states-${target_aws_region}/${env_name}/jenkins.tfstate 

echo "# # # # # # # # E N D # # # # # # # # # #"