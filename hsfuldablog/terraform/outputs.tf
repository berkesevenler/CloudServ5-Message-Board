output "loadbalancer_floating_ip" {
  description = "Floating IP for the load balancer"
  value       = openstack_networking_floatingip_v2.lb_fip.address
}

output "instance_private_ips" {
  description = "Private IPs of the application instances"
  value       = [for inst in openstack_compute_instance_v2.docker_instance : inst.access_ip_v4]
}
