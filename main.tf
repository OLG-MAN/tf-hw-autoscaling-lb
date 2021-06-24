terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.73.0"
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
  name           = "my-instance-template"
  machine_type   = "e2-medium"
  region         = "europe-central2"
  
  tags           = ["web-server"]

  disk {
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {

    }
  }

  metadata = {
    startup-script-url = "gs://hw-bucket-8989/startup.sh"
  }
}

resource "google_compute_autoscaler" "autosc" {
  name   = "my-autoscaler"
  zone   = "europe-central2-c"
  target = google_compute_instance_group_manager.instance_group_manager.self_link

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "igm"
  base_instance_name = "instance-template"
  zone               = "europe-central2-c"

  version {
    instance_template  = google_compute_instance_template.instance_template.id
  }

  target_pools       = [google_compute_target_pool.tpool.self_link]
}

resource "google_compute_target_pool" "tpool" {
  name = "hw-target-pool"
  region = "europe-central2"
}

module "lb" {
  source  = "GoogleCloudPlatform/lb/google"
  version = "2.2.0"
  region       = "europe-central2"
  name         = "load-balancer2"
  service_port = 80
  target_tags  = ["webserver"]
  network      = google_compute_network.vpc_network.name
}



### module for testing
# module "gce-lb-http" {
#   source  = "GoogleCloudPlatform/lb-http/google"
#   name         = "lb-webserver"
#   project      = "project-hw-101"
#   target_tags  = ["web-server"]
#   backends     = {
#     "0" = [
#       { group = "${google_compute_instance_group_manager.instance_group_manager.instance_group}"}
#     ],
#   }
#   backend_params = [
#     "/,http.80,10"
#   ]
# }



### instance for testing
# resource "google_compute_instance" "default" {
#   name         = "test"
#   machine_type = "e2-medium"
#   zone         = "us-central1-a"

#   tags = ["web-server"]

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-9"
#     }
#   }

#   network_interface {
#     network = google_compute_network.vpc_network.name

#     access_config {
#       // Ephemeral IP
#     }
#   }

#   metadata = {
#     startup-script-url = "gs://hw-bucket-8989/startup.sh"
#   }
# }