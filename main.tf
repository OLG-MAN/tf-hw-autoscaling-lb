terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
   credentials = file("gentle-land-312906-f134ad269a49.json")
   project = "gentle-land-312906"
   region  = "us-central1"
   zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "hw-terraform-network"
}

resource "google_storage_bucket" "hw-bucket-8989" {
  name     = "hw-bucket-8989"
 location = "EU"
}

resource "google_storage_bucket_object" "startup-script" {
  name   = "startup.sh"
  source = "startup.sh"
  bucket = "hw-bucket-8989"
}

resource "google_compute_instance" "web server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
    
    access_config {
    
    } 

  }

  metadata = {
    startup-script-url = "gs://hw-bucket-8989/startup.sh"
  }
}