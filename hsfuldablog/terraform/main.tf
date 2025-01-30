# Define IntServ group number
variable "group_number" {
  type    = string
  default = "5"
}

# Commenting out the locals block for future reference

locals {
  auth_url          = var.auth_url
  user_name         = var.user_name
  user_password     = var.user_password
  tenant_name       = var.tenant_name
  project_id        = var.project_id
  user_domain_name  = var.user_domain_name
  cacert_file       = var.cacert_file
  region_name       = var.region_name
  router_name       = var.router_name
  dns_servers       = var.dns_servers
  pubnet_name       = var.pubnet_name
  image_name        = var.image_name
  flavor_name       = var.flavor_name
  
}




terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  auth_url          = var.auth_url
  user_name         = var.user_name
  password          = var.user_password
  tenant_name       = var.tenant_name
  tenant_id         = var.project_id
  user_domain_name  = var.user_domain_name
  region            = var.region_name
  cacert_file       = var.cacert_file
}

# Reference existing keypair
data "openstack_compute_keypair_v2" "terraform_keypair" {
  name = var.key_pair
}

# Declare the main security group
resource "openstack_networking_secgroup_v2" "terraform_secgroup" {
  name        = "my-terraform-secgroup"
  description = "Security group for Docker instance"
}


# Allow inbound HTTP on port 8080
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_http" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

# Allow inbound backend port 5001
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_backend" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5001
  port_range_max    = 5001
  remote_ip_prefix  = "0.0.0.0/0"
}

# Allow inbound SSH on port 22
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ssh" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

# Declare the networking resources
resource "openstack_networking_network_v2" "terraform_network" {
  name           = "my-terraform-network-1"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "terraform_subnet" {
  name            = "my-terraform-subnet-1"
  network_id      = openstack_networking_network_v2.terraform_network.id
  cidr            = "192.168.255.0/24" # Adjust CIDR as needed
  ip_version      = 4
  dns_nameservers = local.dns_servers
}

###############################################################################
# Attach Subnet to an Existing Router (if you have one)
###############################################################################
data "openstack_networking_router_v2" "existing_router" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.existing_router.id
  subnet_id = openstack_networking_subnet_v2.terraform_subnet.id
}

###############################################################################
# Create Compute Instances
###############################################################################
resource "openstack_compute_instance_v2" "docker_instances" {
  count             = 3
  name              = "docker-instance-${count.index + 1}"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = data.openstack_compute_keypair_v2.terraform_keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform_secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform_subnet]

  network {
    uuid = openstack_networking_network_v2.terraform_network.id
  }

user_data = <<-EOT
    #!/bin/bash
    apt-get update

    # Install necessary packages
    apt-get install -y ca-certificates curl git

    # Install Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository to apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add the default cloud image user to the docker group
    usermod -aG docker ubuntu

    # Enable and start Docker services
    systemctl enable docker.service
    systemctl enable containerd.service
    systemctl start docker

    # Clone your GitHub repository containing docker-compose.yml
    git clone https://github.com/berkesevenler/CloudServ5-Message-Board.git /tmp/myapp

    # Navigate to the cloned directory
    cd /tmp/myapp

    # Run docker-compose
    docker compose up -d
  EOT
}

###############################################################################
# Create Load Balancer
###############################################################################
resource "openstack_lb_loadbalancer_v2" "lb_1" {
  name           = "my-terraform-lb"
  vip_subnet_id  = openstack_networking_subnet_v2.terraform_subnet.id
  admin_state_up = true
}

resource "openstack_lb_listener_v2" "listener_1" {
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb_1.id
  protocol         = "HTTP"
  protocol_port    = 80
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool_1" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.id
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
}

# Create Load Balancer Members
resource "openstack_lb_member_v2" "members" {
  count         = 3
  pool_id       = openstack_lb_pool_v2.pool_1.id
  address       = openstack_compute_instance_v2.docker_instances[count.index].access_ip_v4
  protocol_port = 8080
}

# Optional: Create a Health Monitor for the Load Balancer
resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id        = openstack_lb_pool_v2.pool_1.id
  type           = "HTTP"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = "200"
}

###############################################################################
# Assign Floating IP to Load Balancer
###############################################################################
resource "openstack_networking_floatingip_v2" "lb_floating_ip" {
  pool    = local.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb_1.vip_port_id
}

###############################################################################
# Outputs
###############################################################################
output "loadbalancer_floating_ip" {
  description = "Floating IP for the load balancer"
  value       = openstack_networking_floatingip_v2.lb_floating_ip.address
}

output "private_ips" {
  description = "Private IPs of the Docker instances"
  value       = [for instance in openstack_compute_instance_v2.docker_instances : instance.access_ip_v4]
}
