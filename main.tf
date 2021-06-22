terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file("project-hw-101-1c220d18bdd8.json")
  project     = "project-hw-101"
}

resource "google_compute_network" "vpc_network" {
  name        = "hw-terraform-network"
}

resource "google_compute_firewall" "default" {
  name        = "vpc-firewall"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol  = "icmp"
  }

  allow {
    protocol  = "tcp"
    ports     = ["80", "8080", "443", "22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  source_tags   = ["web-server"]
}

resource "google_storage_bucket" "bucket" {
  name     = "hw-bucket-8989"
  location = "EU"
}

resource "google_storage_bucket_object" "startup-script" {
  name   = "startup.sh"
  source = "startup.sh"
  bucket = "hw-bucket-8989"
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix  = "instance-template-"
  machine_type = "e2-medium"
  region       = "europe-central2"
  
  tags         = ["web-server"]

  disk {
    source_image      = "debian-cloud/debian-9"
    auto_delete       = true
    boot              = true
  }

  network_interface {
    network = "hw-terraform-network"
    access_config {

    } 
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata = {
    startup-script-url = "gs://hw-bucket-8989/startup.sh"
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "instance-group-manager"
  instance_template  = google_compute_instance_template.instance_template.id
  base_instance_name = "instance-group-manager"
  zone               = "europe-central2-c"
  target_size        = "3"
}