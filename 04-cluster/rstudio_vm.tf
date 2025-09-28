# ==========================================================================================
# Google Compute Instance: RStudio VM
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Provisions a low-cost VM for RStudio Server
#   - Uses a custom Packer-built image as the boot disk
#   - Connects to an existing VPC and subnet for network access
#   - Attaches firewall tags to allow web and SSH access
# ==========================================================================================

resource "google_compute_instance" "rstudio_vm" {
  name         = "rstudio-vm"                 # Human-readable VM name
  machine_type = "e2-standard-2"              # VM size (2 vCPU, 8 GB RAM)
  zone         = "us-central1-a"              # Zone; must match subnet region
  allow_stopping_for_update = true            # Safe updates without rebuild

  # ----------------------------------------------------------------------------------------
  # Boot Disk
  # - Uses a Packer image for consistent pre-installed setup
  # ----------------------------------------------------------------------------------------
  boot_disk {
    initialize_params {
      image = data.google_compute_image.rstudio_packer_image.self_link
      # Reference the Packer-built image via its self_link
    }
  }

  # ----------------------------------------------------------------------------------------
  # Network Interface
  # - Attaches to VPC and subnet
  # - Creates ephemeral public IP for internet access
  # ----------------------------------------------------------------------------------------
  network_interface {
    network    = data.google_compute_network.packer_vpc.id
    subnetwork = data.google_compute_subnetwork.packer_subnet.id

    access_config {} # Attach NAT IP for outbound/inbound traffic
  }

  # ----------------------------------------------------------------------------------------
  # Startup Script
  # - Executes on boot with values injected at runtime
  # ----------------------------------------------------------------------------------------
  metadata_startup_script = templatefile("./scripts/rstudio_booter.sh", {
    nfs_server_ip = data.google_filestore_instance.nfs_server.networks[0].ip_addresses[0]
    domain_fqdn   = var.dns_zone
    force_group   = "rstudio-users"
  })

  # ----------------------------------------------------------------------------------------
  # Firewall Tags
  # - Enables firewall rules to permit access (SSH, RStudio web UI)
  # ----------------------------------------------------------------------------------------
  tags = ["allow-rstudio"]
}


# ==========================================================================================
# Firewall Rule: Allow RStudio (Web + SSH)
# ------------------------------------------------------------------------------------------
# Purpose:
#   - Opens TCP ports 8787 (RStudio), 22 (SSH), and 80 (HTTP)
#   - Applies only to instances tagged "allow-rstudio"
#   - Uses wide-open source range (0.0.0.0/0) for lab/demo use
#   - ⚠️ Must restrict in production environments
# ==========================================================================================
resource "google_compute_firewall" "allow_rstudio" {
  name    = "allow-rstudio"
  network = "ad-vpc"

  allow {
    protocol = "tcp"
    ports    = ["8787", "22", "80"]
  }

  target_tags   = ["allow-rstudio"] # Apply only to tagged VMs
  source_ranges = ["0.0.0.0/0"]     # ⚠️ Open internet access (lab only)
}
