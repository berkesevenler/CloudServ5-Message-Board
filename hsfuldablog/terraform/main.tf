# Define IntServ group number
variable "group_number" {
  type    = string
  default = "5"
}

# Define OpenStack credentials, project config etc.
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

# Configure the OpenStack Provider
provider "openstack" {
  auth_url    = var.auth_url
  username    = var.user_name
  password    = var.user_password
  tenant_name = var.tenant_name
  tenant_id   = var.project_id
  user_domain_name  = var.user_domain_name
  region      = var.region_name
  cacert_file = var.cacert_file
}

# Reference existing keypair
data "openstack_compute_keypair_v2" "terraform-keypair" {
  name = var.key_pair
}

# Create instances
resource "openstack_compute_instance_v2" "terraform-instance-1" {
  name              = "my-terraform-instance-1"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = data.openstack_compute_keypair_v2.terraform-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get -y install apache2
    rm /var/www/html/index.html
    cat > /var/www/html/index.html << INNEREOF
    <!DOCTYPE html>
    <html>
      <body>
        <h1>It works!</h1>
        <p>hostname</p>
      </body>
    </html>
    INNEREOF
    sed -i "s/hostname/terraform-instance-1/" /var/www/html/index.html
    sed -i "1s/$/ terraform-instance-1/" /etc/hosts
  EOF
}

resource "openstack_compute_instance_v2" "terraform-instance-2" {
  name            = "my-terraform-instance-2"
  image_name      = local.image_name
  flavor_name     = local.flavor_name
  key_pair        = data.openstack_compute_keypair_v2.terraform-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get -y install apache2
    rm /var/www/html/index.html
    cat > /var/www/html/index.html << INNEREOF
    <!DOCTYPE html>
    <html>
      <body>
        <h1>It works!</h1>
        <p>hostname</p>
      </body>
    </html>
    INNEREOF
    sed -i "s/hostname/terraform-instance-2/" /var/www/html/index.html
    sed -i "1s/$/ terraform-instance-2/" /etc/hosts
  EOF
}

# Create load balancer (no floating IP handled in Terraform)
resource "openstack_lb_loadbalancer_v2" "lb_1" {
  vip_subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}

resource "openstack_lb_listener_v2" "listener_1" {
  protocol         = "HTTP"
  protocol_port    = 80
  loadbalancer_id  = openstack_lb_loadbalancer_v2.lb_1.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool_1" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener_1.id
}

resource "openstack_lb_members_v2" "members_1" {
  pool_id = openstack_lb_pool_v2.pool_1.id

  member {
    address       = openstack_compute_instance_v2.terraform-instance-1.access_ip_v4
    protocol_port = 80
  }

  member {
    address       = openstack_compute_instance_v2.terraform-instance-2.access_ip_v4
    protocol_port = 80
  }
}

# Create Docker instance
resource "openstack_compute_instance_v2" "docker_instance" {
  name            = "docker-instance"
  image_name      = var.docker_image_name
  flavor_name     = var.docker_flavor_name
  key_pair        = var.key_pair
  security_groups = [openstack_networking_secgroup_v2.docker_secgroup.name]

  network {
    uuid = openstack_networking_network_v2.docker_network.id
  }

  user_data = <<-EOT
    #!/bin/bash
    # Update and install required packages
    apt-get update
    apt-get install -y git docker.io

    # Enable Docker to start on boot
    systemctl start docker
    systemctl enable docker

    # Clone the GitHub repository
    git clone https://github.com/your-username/message-board.git /message-board

    # Navigate to the cloned directory
    cd /message-board

    # Build the Docker image
    docker build -t message-board-app .

    # Optionally, push the image to Docker Hub
    docker login -u "your-dockerhub-username" -p "your-dockerhub-password"
    docker tag message-board-app your-dockerhub-username/message-board-app:latest
    docker push your-dockerhub-username/message-board-app:latest

    # Run the container
    docker run -d -p 80:80 --name message-board message-board-app
  EOT
}

# Networking Resources for Docker
resource "openstack_networking_network_v2" "docker_network" {
  name = var.docker_network_name
}

resource "openstack_networking_subnet_v2" "docker_subnet" {
  network_id = openstack_networking_network_v2.docker_network.id
  cidr       = var.docker_subnet_cidr
  ip_version = 4
  gateway_ip = var.docker_gateway_ip
}

resource "openstack_networking_router_v2" "docker_router" {
  name = var.docker_router_name
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.docker_router.id
  subnet_id = openstack_networking_subnet_v2.docker_subnet.id
}

# Security Group for Docker
resource "openstack_networking_secgroup_v2" "docker_secgroup" {
  name = var.docker_secgroup_name
}

resource "openstack_networking_secgroup_rule_v2" "allow_http" {
  security_group_id = openstack_networking_secgroup_v2.docker_secgroup.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

# Output the instance public IP
output "instance_ip" {
  value = openstack_compute_instance_v2.docker_instance.access_ip_v4
}

# Output manually assigned floating IP
output "loadbalancer_vip_addr" {
  value = "10.32.6.117"
}
