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
   project = "project-hw-101"
#    region  = "us-central1"
#    zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "hw-terraform-network"
  # auto_create_subnetworks = false
}

# resource "google_compute_subnetwork" "vpc_sub_network_1" {
#   name          = "subnetwork-1" 
#   ip_cidr_range = "10.0.10.0/24"
#   region        = "europe-central2"
#   network       = google_compute_network.vpc_network.id
# }

# resource "google_compute_subnetwork" "vpc_sub_network_2" {
#   name          = "subnetwork-2" 
#   ip_cidr_range = "10.0.20.0/24"
#   region        = "europe-central2"
#   network       = google_compute_network.vpc_network.id
# }

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "443", "22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  source_tags = ["web-server"]
}


resource "google_storage_bucket" "bucket" {
  name     = "hw-bucket-8989"
  location = "EU"
}

resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.bucket.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_object" "startup-script" {
  name   = "startup.sh"
  source = "startup.sh"
  bucket = "hw-bucket-8989"
}

resource "google_compute_instance" "webserver" {
  name         = "web-server"
  machine_type = "e2-medium"   
  zone         = "europe-central2-c"

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "hw-terraform-network"
    access_config {

    }     
  }

  metadata = {
    startup-script-url = "gs://hw-bucket-8989/startup.sh"
  }
}

resource "google_compute_instance_group_manage" "webservers" {
  name               = "hw-webservers"
  instance_template  = "${google_compute_instance_template.webserver.self_link}"
  base_instance_name = "webserver"
  zone               = "europe-central2-c"
  target_size        = 2
  named_port {
    name = "http"
    port = 80
  }
}

module "gce-lb-http" {
  source            = "GoogleCloudPlatform/lb-http/google"
  name              = "webserver"
  target_tags       = ["http"]
  backends          = {
    "0" = [
      { group = "${google_compute_instance_group_maager.weservers.instance_group}"}
    ],
  }
  backend_params    = [
    "/,http,80,10"
  ]
}

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "5.1.1"
  name              = "webserver"
  target_tags       = ["http"]
  backends          = {
    "0" = [
      { group = "${google_compute_instance_group_maager.weservers.instance_group}"}
    ],
  }
  backend_params    = [
    "/,http,80,10"
  ]
}