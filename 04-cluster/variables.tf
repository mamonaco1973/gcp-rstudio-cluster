############################################
# INPUT VARIABLES: NETWORK RESOURCES
############################################

# Defines a string input variable for the name of the existing VPC
# Allows flexibility across environments by avoiding hardcoded VPC names
variable "vpc_name" {
  description = "Name of the existing VPC network"  # Describes the purpose of this input (critical for modular deployments)
  type        = string                              # Ensures only string values are accepted
  default     = "ad-vpc"
}

# Defines a string input variable for the name of the existing subnet
# Enables reusability of the module in any region or VPC structure
variable "subnet_name" {
  description = "Name of the existing subnetwork"   # Clear description for input validation and documentation
  type        = string                              # Must be a valid string representing the subnet name
  default     = "ad-subnet"
}

############################################
# INPUT VARIABLES: PACKER IMAGE NAMES
############################################


variable "rstudio_image_name" {
  description = "Name of the Packer built rstudio image"  # Explicitly describes the image being referenced
  type        = string                                  # Must be a string; typically something like "rstudio-ubuntu-20240418"
}

# Data source to lookup the actual image object in GCP based on the name and project
# Ensures that Terraform can retrieve the image metadata and use it for VM boot disks
data "google_compute_image" "rstudio_packer_image" {
  name    = var.rstudio_image_name               # Dynamically reference the image name provided by the variable
  project = local.credentials.project_id       # Use the project ID from the decoded credentials (avoids hardcoding)
}

