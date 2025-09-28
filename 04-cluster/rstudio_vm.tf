############################################
# GOOGLE COMPUTE INSTANCE: RSTUDIO VM
############################################

# Creates a low-cost, publicly accessible virtual machine instance
# Based on a custom Packer image, attached to existing VPC and subnet
resource "google_compute_instance" "rstudio_vm" {
  name         = "rstudio-vm"              # Human-readable name for the VM in the GCP console
  machine_type = "e2-standard-2"              
  zone         = "us-central1-a"         # Specific availability zone for this instance (must match subnet region)
  allow_stopping_for_update = true       # Allows the instance to be stopped temporarily during updates (saves cost and prevents rebuilds)

  ########################################
  # BOOT DISK CONFIGURATION
  ########################################

  # Define the boot disk for the VM using a custom Packer image
  # Ensures consistent VM setup with pre-installed software or config baked into the image
  boot_disk {
    initialize_params {
      image = data.google_compute_image.rstudio_packer_image.self_link  # Reference the full self_link to the image from earlier data block
    }
  }

  ########################################
  # NETWORK INTERFACE CONFIGURATION
  ########################################

  # Attach the VM to an existing VPC and subnetwork
  # Required for the VM to have internal and external connectivity
  network_interface {
    network    = data.google_compute_network.packer_vpc.id        # Reference the VPC ID from the data lookup
    subnetwork = data.google_compute_subnetwork.packer_subnet.id  # Reference the subnet ID for IP range allocation

    access_config {}  # Creates and attaches an ephemeral public IP (via NAT) to the VM for internet access
  }

  ########################################
  # STARTUP SCRIPT EXECUTION
  ########################################

  # Pass a startup script to the VM to execute on boot
  # Uses templatefile() to inject dynamic values (e.g., image name) into the script at runtime
  metadata_startup_script = templatefile("./scripts/rstudio_booter.sh", {
  
  })

  ########################################
  # FIREWALL TAGS
  ########################################

  # Attach tags used by firewall rules to permit specific traffic (e.g., SSH, HTTP)
  # These tags must match firewall rule target tags defined elsewhere
  tags = ["allow-rstudio"]            # Enable SSH (port 22) and HTTP (port 80) traffic into this VM
}


# ================================================================================================
# Firewall Rule: Allow RStudio (Web Interface)
# ================================================================================================
# Opens TCP port 8787 for RStudio access to VMs tagged with "allow-rstudio".
#
# Key Points:
#   - Applies only to instances with "allow-rstudio" tag.
#   - Source range is open to the internet (0.0.0.0/0) — ⚠️ restrict in production.
# ================================================================================================
resource "google_compute_firewall" "allow_rstudio" {
  name    = "allow-rstudio"
  network = "ad-vpc"

  allow {
    protocol = "tcp"
    ports    = ["8787", "22", "80"]
  }

  # Tag-based targeting (applies only to instances with this tag)
  target_tags = ["allow-rstudio"]

  # ⚠️ Lab only; tighten for production
  source_ranges = ["0.0.0.0/0"]
}
