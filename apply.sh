#!/bin/bash

set -e  # Exit immediately on any unhandled command failure

# Run the environment check script to ensure required environment variables, tools, or configurations are present.
./check_env.sh
if [ $? -ne 0 ]; then
  # If the check_env script exits with a non-zero status, it indicates a failure.
  echo "ERROR: Environment check failed. Exiting."
  exit 1  # Stop script execution immediately if environment check fails.
fi

# Phase 1 of the build - Build active directory
cd 01-directory

# Initialize Terraform (download providers, set up backend, etc.).
terraform init

# Apply the Terraform configuration, automatically approving all changes (no manual confirmation required).
terraform apply -auto-approve

if [ $? -ne 0 ]; then
  echo "ERROR: Terraform apply failed in 01-directory. Exiting."
  exit 1
fi

# Return to the previous (parent) directory.
cd ..

# Phase 2 of the build - Build VMs connected to active directory
cd 02-servers

# Initialize Terraform (download providers, set up backend, etc.) for server deployment.
terraform init

# Apply the Terraform configuration, automatically approving all changes (no manual confirmation required).
terraform apply -auto-approve

# Return to the parent directory once server provisioning is complete.
cd ..

# Phase 3 of the build - Build the RStudio image

project_id=$(jq -r '.project_id' "./credentials.json")
gcloud auth activate-service-account --key-file="./credentials.json" > /dev/null 2> /dev/null
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/credentials.json"

cd 03-packer
packer build \
  -var="project_id=$project_id" \
  rstudio_image.pkr.hcl
cd ..

./validate.sh

