packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1.1.6"
    }
  }
}
############################################
# LOCALS: TIMESTAMP UTILITY
############################################

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") # Generate compact timestamp (YYYYMMDDHHMMSS)
                                                       # Used for unique image names
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "source_image_family" {
  description = "Source image family to base the build on (e.g., ubuntu-2404-lts-amd64)"
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}


source "googlecompute" "rstudio_build_image" {
  project_id            = var.project_id
  zone                  = var.zone
  source_image_family   = var.source_image_family # Specifies the base image family
  ssh_username          = "ubuntu"                # Specify the SSH username
  machine_type          = "e2-standard-2"            

  image_name            = "rstudio-image-${local.timestamp}" 
                                                  # Use local.timestamp directly
  image_family          = "rstudio-images"        # Image family to group related images
  disk_size             = 20                      # Disk size in GB
}

# ------------------------------------------------------------------------------------------
# Build Block: Provisioning Scripts
# - Executes provisioning scripts inside the temporary VM
# - Each script installs specific components
# ------------------------------------------------------------------------------------------
build {
  sources = ["source.googlecompute.rstudio_build_image"]  

  # Install base packages and dependencies
  provisioner "shell" {
    script          = "./packages.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }

  # Install and configure RStudio Server
  provisioner "shell" {
    script          = "./rstudio.sh"
    execute_command = "sudo -E bash '{{.Path}}'"
  }
}
