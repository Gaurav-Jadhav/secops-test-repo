#first we created a custom VPC
resource "google_compute_network" "custom_network" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
}

#create single subnet and associate subnet with above created VPC
resource "google_compute_subnetwork" "custom-subnet" {
  name          = "custom-subnetwork"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.custom_network.id
}

#internal communication firewall 1  rule 
resource "google_compute_firewall" "allow-internal" {
  name    = "internal-firewall"
  network = google_compute_network.custom_network.id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.10.0.0/16"]
}


#external communication firewall 2 SSH icmp RDP

resource "google_compute_firewall" "allow-external" {
  name    = "external-firewall"
  network = google_compute_network.custom_network.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = [ "22","3389" ]
  }


  source_ranges = ["0.0.0.0/0"]
}


#GKE  communication firewall 3 and associated this 3 firewall rules with VPC

resource "google_compute_firewall" "allow-gke" {
  name    = "gke-firewall"
  network = google_compute_network.custom_network.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports = [ "443","10250", "15017" ]  #10250 kublet api communication port #15017 sterio control plane communication
  }


  source_ranges = ["0.0.0.0/0"]
}

#create GKE Cluster
resource "google_container_cluster" "primary" {
  project     = var.project
  name = "terraform-gke-cluster1"
  location = var.zone
  network = google_compute_network.custom_network.id
  subnetwork = google_compute_subnetwork.custom-subnet.id
  min_master_version = var.K8s_version
  deletion_protection = false
  enable_shielded_nodes    = "true"
  remove_default_node_pool = true
  initial_node_count = var.node_count

  release_channel {
    channel = "REGULAR" # Or RAPID, STABLE
  }


}
#create container node pool
resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  project =    google_container_cluster.primary.project
  location   = google_container_cluster.primary.location
  cluster    = google_container_cluster.primary.name
  version = var.K8s_version
  node_count = var.node_count



  node_config {
    image_type = "cos_containerd"
    machine_type = "e2-medium"
    disk_size_gb = 75
    disk_type = "pd-standard"
  }

    autoscaling {
    min_node_count = 1
    max_node_count = 2

    }
    management {
    auto_repair = true
    auto_upgrade =  true
}
}