#!/bin/bash

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

./validate.sh

