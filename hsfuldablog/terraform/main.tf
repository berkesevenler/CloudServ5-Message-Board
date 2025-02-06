terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
  }
}

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

# --- Keypair ---
data "openstack_compute_keypair_v2" "terraform_keypair" {
  name = var.key_pair
}

# --- Security Group and Rules ---
resource "openstack_networking_secgroup_v2" "app_secgroup" {
  name        = "app_secgroup"
  description = "Security group for application instances"
}

resource "openstack_networking_secgroup_rule_v2" "rule_backend" {
  security_group_id = openstack_networking_secgroup_v2.app_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5001
  port_range_max    = 5001
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "rule_frontend" {
  security_group_id = openstack_networking_secgroup_v2.app_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "rule_ssh" {
  security_group_id = openstack_networking_secgroup_v2.app_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

# --- Networking ---
resource "openstack_networking_network_v2" "app_network" {
  name           = "app_network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "app_subnet" {
  name           = "app_subnet"
  network_id     = openstack_networking_network_v2.app_network.id
  cidr           = "192.168.100.0/24"
  ip_version     = 4
  dns_nameservers = var.dns_servers
}

data "openstack_networking_router_v2" "router" {
  name = var.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = data.openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.app_subnet.id
}

# --- Compute Instances ---
resource "openstack_compute_instance_v2" "docker_instance" {
  count           = var.instance_count
  name            = "app-instance-${count.index + 1}"
  image_name      = var.image_name
  flavor_name     = var.flavor_name
  key_pair        = data.openstack_compute_keypair_v2.terraform_keypair.name
  security_groups = [openstack_networking_secgroup_v2.app_secgroup.name]

  network {
    uuid = openstack_networking_network_v2.app_network.id
  }

  # Cloud-init: install Docker, Docker Compose, clone your repository, and start the Compose stack
  user_data = file("user_data.sh")
}

# --- Load Balancer (for Frontend) ---
resource "openstack_lb_loadbalancer_v2" "lb" {
  name           = "app-lb"
  vip_subnet_id  = openstack_networking_subnet_v2.app_subnet.id
  admin_state_up = true
}

resource "openstack_lb_listener_v2" "listener" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb.id
  protocol        = "HTTP"
  protocol_port   = 80
}

resource "openstack_lb_pool_v2" "pool" {
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb.id
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
}

resource "openstack_lb_member_v2" "member" {
  count          = var.instance_count
  pool_id        = openstack_lb_pool_v2.pool.id
  address        = openstack_compute_instance_v2.docker_instance[count.index].access_ip_v4
  protocol_port  = 8080
}

resource "openstack_lb_monitor_v2" "monitor" {
  pool_id        = openstack_lb_pool_v2.pool.id
  type           = "HTTP"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = "200"
}

resource "openstack_networking_floatingip_v2" "lb_fip" {
  pool    = var.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb.vip_port_id
}
