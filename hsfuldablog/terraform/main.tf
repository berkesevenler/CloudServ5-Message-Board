# Define IntServ group number
variable "group_number" {
  type    = string
  default = "5"
}

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
  dns_servers       = ["8.8.8.8", "8.8.4.4"]  # Use Google's public DNS servers
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

data "openstack_compute_keypair_v2" "terraform_keypair" {
  name = var.key_pair
}

resource "openstack_networking_secgroup_v2" "terraform_secgroup" {
  name        = "my-terraform-secgroup"
  description = "Security group for Docker instance"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_http" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_backend" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5001
  port_range_max    = 5001
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ssh" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_mongodb_ingress" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 27017
  port_range_max    = 27017
  remote_ip_prefix  = "0.0.0.0/0" # Change this to a more restrictive range if possible
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_outbound" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_outbound_https" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
}

# Add to your security group rules
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_mongodb" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 27017
  port_range_max    = 27017
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_outbound_all" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  remote_ip_prefix = "0.0.0.0/0"
  port_range_min   = 1
  port_range_max   = 65535
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_dns" {
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "udp"
  port_range_min   = 53
  port_range_max   = 53
  remote_ip_prefix = "0.0.0.0/0"
}


resource "openstack_networking_network_v2" "terraform_network" {
  name           = "my-terraform-network-1"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "terraform_subnet" {
  name            = "my-terraform-subnet-1"
  network_id      = openstack_networking_network_v2.terraform_network.id
  cidr            = "192.168.255.0/24"
  ip_version      = 4
  dns_nameservers = local.dns_servers
}

data "openstack_networking_router_v2" "existing_router" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.existing_router.id
  subnet_id = openstack_networking_subnet_v2.terraform_subnet.id
}

resource "openstack_compute_instance_v2" "docker_instances" {
  count             = 3
  name              = "docker-instance-${count.index + 1}"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = data.openstack_compute_keypair_v2.terraform_keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform_secgroup.name]

  network {
    uuid = openstack_networking_network_v2.terraform_network.id
  }

  user_data = <<-EOT
    #cloud-config
    package_update: true
    package_upgrade: true

    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - software-properties-common
      - docker.io
      - docker-compose
      - git

    runcmd:
      # Enable and start Docker
      - systemctl enable docker
      - systemctl start docker

      # Clone and setup application
      - mkdir -p /tmp/myapp
      - cd /tmp/myapp
      - git clone https://github.com/berkesevenler/CloudServ5-Message-Board.git .

    # 1) Replace REPLACE_LB_FIP in scripts.js with the actual floating IP
      
      - sed -i "s/REPLACE_LB_FIP/${openstack_networking_floatingip_v2.lb_floating_ip.address}/g" /tmp/myapp/hsfuldablog/frontend/scripts.js

      # Run Docker Compose
      - cd /tmp/myapp/hsfuldablog
      - docker-compose down --remove-orphans || true
      - docker-compose pull
      - COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d

      # Debugging - Log Docker status
      - echo "Docker containers status:" >> /var/log/docker-status.log
      - docker ps -a >> /var/log/docker-status.log
      - echo "Docker Compose logs:" >> /var/log/docker-status.log
      - docker-compose logs >> /var/log/docker-status.log

    write_files:
      - path: /etc/docker/daemon.json
        content: |
          {
            "log-driver": "json-file",
            "log-opts": {
              "max-size": "100m",
              "max-file": "3"
            }
          }
        owner: root:root
        permissions: '0644'

    final_message: "System configuration completed after $UPTIME seconds"
  EOT
}

resource "openstack_lb_loadbalancer_v2" "lb_1" {
  name           = "my-terraform-lb"
  vip_subnet_id  = openstack_networking_subnet_v2.terraform_subnet.id
  admin_state_up = true
}

resource "openstack_lb_listener_v2" "listener_1" {
  name            = "my-listener"
  protocol        = "HTTP"
  protocol_port   = 8080
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.id
}

resource "openstack_lb_pool_v2" "pool_1" {
  name        = "my-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener_1.id
}

resource "openstack_lb_member_v2" "member_1" {
  count   = 2
  pool_id = openstack_lb_pool_v2.pool_1.id
  address = openstack_compute_instance_v2.docker_instances[count.index].network.0.fixed_ip_v4
  protocol_port = 8080
}

resource "openstack_lb_listener_v2" "listener_backend_5001" {
  name            = "my-backend-listener"
  protocol        = "HTTP"
  protocol_port   = 5001
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.id
}

resource "openstack_lb_pool_v2" "pool_backend_5001" {
  name        = "my-backend-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener_backend_5001.id
}

resource "openstack_lb_member_v2" "member_backend_5001" {
  count         = 2
  pool_id       = openstack_lb_pool_v2.pool_backend_5001.id
  # Use the VM’s private IP for address
  address       = openstack_compute_instance_v2.docker_instances[count.index].network.0.fixed_ip_v4
  protocol_port = 5001  # The container’s published host port for backend
}

resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id     = openstack_lb_pool_v2.pool_1.id
  type        = "HTTP"
  delay       = 5
  timeout     = 3
  max_retries = 3
  url_path    = "/"
}

resource "openstack_networking_floatingip_v2" "lb_floating_ip" {
  pool    = local.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb_1.vip_port_id
}

output "loadbalancer_floating_ip" {
  description = "Floating IP for the load balancer"
  value       = openstack_networking_floatingip_v2.lb_floating_ip.address
}

output "private_ips" {
  description = "Private IPs of the Docker instances"
  value       = [for instance in openstack_compute_instance_v2.docker_instances : instance.access_ip_v4]
}