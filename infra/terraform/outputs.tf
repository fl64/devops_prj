output "gitlab_external_ip" {
  value = "${google_compute_instance.dockerhost_gitlab.*.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "prod_external_ip" {
  value = "${google_compute_instance.dockerhost_prod.*.network_interface.0.access_config.0.assigned_nat_ip}"
}
