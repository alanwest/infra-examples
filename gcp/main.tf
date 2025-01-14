terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "opentracing-265818"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_instance" "vm_instance" {
  name                      = "apm-infra-gcp-vm"
  machine_type              = "n1-standard-1"
  allow_stopping_for_update = false
  boot_disk {
    initialize_params {
      image = "ubuntu-os-pro-cloud/ubuntu-pro-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_tr_network.self_link
    access_config {
    }
  }

  metadata = {
    startup-script = <<SCRIPT
    ${templatefile("templates/docker-install.tftpl", {})}
    ${templatefile("templates/docker-compose.tftpl", {})}
    ${templatefile("templates/otel-config.tftpl", {})}
    ${templatefile("templates/vm-setup.tftpl", {})}
    SCRIPT
  }
}

resource "google_compute_network" "vpc_tr_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "ssh-rule" {
  name    = "infra-ssh"
  network = google_compute_network.vpc_tr_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}
