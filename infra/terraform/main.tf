provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

### External IP
#resource "google_compute_address" "dockerhost_ip" {
#  name = "dockerhost-ip"
#}

### Gitlab instance
resource "google_compute_instance" "dockerhost_gitlab" {

  name         = "dockerhost-gitlab"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["gitlab", "docker-host"]

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      #  nat_ip = "${google_compute_address.dockerhost_ip.address}"
    }
  }

  metadata {
    ssh-keys = "dockerhost:${file(var.public_key_path)}"
  }
}

### Prod instance
resource "google_compute_instance" "dockerhost_prod" {

  name         = "dockerhost-prod"
  machine_type = "${var.machine_type}"
  zone         = "${var.zone}"
  tags         = ["prod", "docker-host"]

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
      size  = "${var.disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config = {
      #  nat_ip = "${google_compute_address.dockerhost_ip.address}"
    }
  }

  metadata {
    ssh-keys = "dockerhost:${file(var.public_key_path)}"
  }
}

### Gitlab-CI http
resource "google_compute_firewall" "firewall_gitlab_http" {
  name    = "allow-gitlab-ci-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gitlab"]
}

### All ssh
resource "google_compute_firewall" "firewall_ssh" {
  name    = "allow-ssh-dockerhost"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["docker-host"]
}


### App port
resource "google_compute_firewall" "firewall_app" {
  name    = "allow-app-prod"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["prod","test-app"]
}

resource "google_compute_firewall" "firewall_prometheus" {
  name    = "allow-prometheus-prod"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["prod","app-test"]
}
