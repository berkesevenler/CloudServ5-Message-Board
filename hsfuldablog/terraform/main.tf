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

# Security group rules for monitoring
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_grafana" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 3000
  port_range_max   = 3000
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_prometheus" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9090
  port_range_max   = 9090
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_node_exporter" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9100
  port_range_max   = 9100
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_cadvisor" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 8081
  port_range_max   = 8081
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

# Outbound rules for monitoring services
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_grafana_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 3000
  port_range_max   = 3000
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_prometheus_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9090
  port_range_max   = 9090
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

# Add missing egress rules for Node Exporter and cAdvisor
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_node_exporter_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9100
  port_range_max   = 9100
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_cadvisor_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 8081
  port_range_max   = 8081
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

# Allow internal communication between containers
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_internal_tcp" {
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_ip_prefix = "192.168.255.0/24"  # Your subnet CIDR
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

# Allow HTTPS egress for pulling Docker images
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_https_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
}

# Allow HTTP egress for pulling Docker images and other HTTP traffic
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_http_egress" {
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 80
  port_range_max   = 80
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
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
  # Use the VM's private IP for address
  address       = openstack_compute_instance_v2.docker_instances[count.index].network.0.fixed_ip_v4
  protocol_port = 5001  # The container's published host port for backend
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

resource "openstack_compute_instance_v2" "monitoring_instance" {
  name              = "monitoring-instance"
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

      # Debugging - Log Docker status before setup
      - echo "Initial Docker status:" >> /var/log/docker-status.log
      - systemctl status docker >> /var/log/docker-status.log
      - docker --version >> /var/log/docker-status.log
      - docker-compose --version >> /var/log/docker-status.log

      # Clone and setup monitoring
      - mkdir -p /opt/monitoring
      - cd /opt/monitoring

      # Create monitoring directory structure
      - mkdir -p prometheus
      - mkdir -p grafana/provisioning/datasources
      - mkdir -p grafana/provisioning/dashboards
      - mkdir -p grafana/dashboards

      # Create docker-compose.yml
      - |
        cat > /opt/monitoring/docker-compose.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    restart: unless-stopped
    depends_on:
      - cadvisor
      - node-exporter

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on:
      - prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8081:8081"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    restart: unless-stopped
    privileged: true

volumes:
  prometheus_data:
  grafana_data:
EOF

      # Create Prometheus config
      - cat > /opt/monitoring/prometheus/prometheus.yml <<EOF
        global:
          scrape_interval: 15s
          evaluation_interval: 15s
        
        scrape_configs:
          - job_name: 'prometheus'
            static_configs:
              - targets: ['localhost:9090']
          
          - job_name: 'node-exporter'
            static_configs:
              - targets: ['node-exporter:9100']
          
          - job_name: 'cadvisor'
            static_configs:
              - targets: ['cadvisor:8081']
          
          - job_name: 'docker'
            static_configs:
              - targets: ['${openstack_compute_instance_v2.docker_instances[0].access_ip_v4}:8080', '${openstack_compute_instance_v2.docker_instances[1].access_ip_v4}:8080', '${openstack_compute_instance_v2.docker_instances[2].access_ip_v4}:8080']
        EOF

      # Create Grafana datasource
      - cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml <<EOF
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            access: proxy
            url: http://prometheus:9090
            isDefault: true
        EOF

      # Start monitoring stack
      - cd /opt/monitoring
      - docker-compose down --remove-orphans || true
      - docker-compose pull
      - COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d

      # Debugging - Log final status
      - echo "Final Docker containers status:" >> /var/log/docker-status.log
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

    final_message: "Monitoring setup completed after $UPTIME seconds"
  EOT
}

# Create floating IP for monitoring instance
resource "openstack_networking_floatingip_v2" "monitoring_floating_ip" {
  pool = local.pubnet_name
}

# Associate floating IP with monitoring instance
resource "openstack_networking_floatingip_associate_v2" "monitoring_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.monitoring_floating_ip.address
  port_id    = openstack_compute_instance_v2.monitoring_instance.network[0].port
}

# Output monitoring URLs
output "monitoring_urls" {
  value = {
    grafana    = "http://${openstack_networking_floatingip_v2.monitoring_floating_ip.address}:3000"
    prometheus = "http://${openstack_networking_floatingip_v2.monitoring_floating_ip.address}:9090"
  }
}