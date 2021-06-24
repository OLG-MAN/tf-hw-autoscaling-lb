terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.20.0"
    }
  }
}

provider "google" {
  credentials = file("project-hw-101-1c220d18bdd8.json")
  project     = "project-hw-101"
}

data "google_compute_image" "debian" {
  family  = "debian-10"
  project = "debian-cloud"
}

resource "google_compute_network" "vpc_network" {
  name = "new-terraform-network"
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

resource "google_compute_instance_template" "foobar" {
  name           = "my-instance-template"
  machine_type   = "e2-medium"
  can_ip_forward = false
  tags = ["web-server"]

  disk {
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    network = google_compute_network.vpc_network.name
  }

  metadata = {
    foo = "bar"
  }
  
  metadata_startup_script = "startup.sh"  
}

resource "google_compute_instance_group_manager" "foobar" {
  name = "my-igm"
  zone = "us-central1-c"
  version {
    instance_template  = google_compute_instance_template.foobar.self_link
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.foobar.self_link]
  base_instance_name = "terraform"
}

resource "google_compute_target_pool" "foobar" {
  name = "my-target-pool"
  region = "us-central1"
}

resource "google_compute_autoscaler" "foobar" {
  name   = "my-autoscaler"
  zone   = "us-central1-c"
  target = google_compute_instance_group_manager.foobar.self_link

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

module "lb" {
  source  = "GoogleCloudPlatform/lb/google"
  version = "2.2.0"
  region       = "us-central1"
  name         = "load-balancer"
  service_port = 80
  target_tags  = ["my-target-pool"]
  network      = google_compute_network.vpc_network.name
}