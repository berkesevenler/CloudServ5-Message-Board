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
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9100
  port_range_max    = 9100
  remote_ip_prefix  = "192.168.255.0/24"  # Your subnet CIDR
  security_group_id = openstack_networking_secgroup_v2.terraform_secgroup.id
  description       = "Allow Node Exporter metrics scraping"
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

# Note: HTTP and HTTPS egress rules are already defined above as secgroup_rule_outbound and secgroup_rule_outbound_https

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
write_files:
  - path: /var/log/app-setup.log
    content: "Starting application setup at $(date)\n"
    permissions: '0644'
  - path: /etc/systemd/system/node_exporter.service
    content: |
      [Unit]
      Description=Node Exporter
      After=network.target

      [Service]
      Type=simple
      User=root
      ExecStart=/usr/local/bin/node_exporter --collector.filesystem --collector.meminfo --collector.cpu --collector.diskstats
      Restart=always

      [Install]
      WantedBy=multi-user.target
    permissions: '0644'
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "100m",
          "max-file": "3"
        }
      }
    permissions: '0644'
  - path: /usr/local/bin/setup-app.sh
    content: |
      #!/bin/bash
      set -e
      LOGFILE="/var/log/app-setup.log"
      
      # Record setup start
      echo "Setup script starting execution at $(date)" >> $LOGFILE
      
      # Install Node Exporter for Prometheus metrics
      echo "Installing Node Exporter..." >> $LOGFILE
      mkdir -p /opt/node_exporter
      cd /opt/node_exporter
      curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz >> $LOGFILE 2>&1 || { echo "Failed to download Node Exporter" >> $LOGFILE; exit 1; }
      tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz >> $LOGFILE 2>&1 || { echo "Failed to extract Node Exporter" >> $LOGFILE; exit 1; }
      mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/ >> $LOGFILE 2>&1 || { echo "Failed to move Node Exporter binary" >> $LOGFILE; exit 1; }
      rm -rf node_exporter-1.7.0.linux-amd64* >> $LOGFILE 2>&1

      # Enable and start Node Exporter
      echo "Enabling and starting Node Exporter..." >> $LOGFILE
      systemctl daemon-reload >> $LOGFILE 2>&1 || { echo "Failed to reload systemd" >> $LOGFILE; exit 1; }
      systemctl enable node_exporter >> $LOGFILE 2>&1 || { echo "Failed to enable Node Exporter" >> $LOGFILE; exit 1; }
      systemctl start node_exporter >> $LOGFILE 2>&1 || { echo "Failed to start Node Exporter" >> $LOGFILE; exit 1; }
      
      # Configure firewall for metrics
      echo "Configuring firewall rules..." >> $LOGFILE
      ufw allow 8080/tcp >> $LOGFILE 2>&1 || echo "Warning: Failed to allow port 8080" >> $LOGFILE
      ufw allow 9100/tcp >> $LOGFILE 2>&1 || echo "Warning: Failed to allow port 9100" >> $LOGFILE

      # Clone and setup application
      echo "Cloning application repository..." >> $LOGFILE
      mkdir -p /tmp/myapp
      cd /tmp/myapp
      git clone https://github.com/berkesevenler/CloudServ5-Message-Board.git . >> $LOGFILE 2>&1 || { echo "Failed to clone application repository" >> $LOGFILE; exit 1; }
      
      sed -i "s/REPLACE_LB_FIP/${openstack_networking_floatingip_v2.lb_floating_ip.address}/g" /tmp/myapp/hsfuldablog/frontend/scripts.js

      # Run Docker Compose
      echo "Starting application with Docker Compose..." >> $LOGFILE
      cd /tmp/myapp/hsfuldablog
      docker-compose down --remove-orphans >> $LOGFILE 2>&1 || true
      docker-compose pull >> $LOGFILE 2>&1 || { echo "Failed to pull Docker images" >> $LOGFILE; exit 1; }
      COMPOSE_HTTP_TIMEOUT=200 docker-compose up -d >> $LOGFILE 2>&1 || { echo "Failed to start Docker Compose" >> $LOGFILE; exit 1; }

      # Log Docker status
      echo "Docker containers status:" >> $LOGFILE
      docker ps -a >> $LOGFILE
      echo "Docker Compose logs:" >> $LOGFILE
      docker-compose logs >> $LOGFILE

      echo "Application setup completed at $(date)" >> $LOGFILE
    permissions: '0755'

# Install required packages
package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose
  - curl
  - apt-transport-https
  - ca-certificates
  - git
  - software-properties-common
  - ufw

# Run commands after package installation
runcmd:
  - systemctl enable docker
  - systemctl start docker
  - mkdir -p /etc/docker
  - chmod +x /usr/local/bin/setup-app.sh
  - /usr/local/bin/setup-app.sh
  - systemctl restart docker
  - systemctl status node_exporter
  - echo "#!/bin/bash" > /usr/local/bin/restart-frontend.sh && echo "cd /tmp/myapp/hsfuldablog && docker-compose restart frontend && docker exec -i hsfuldablog_frontend_1 sed -i \"s|http://[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:5001|http://${openstack_networking_floatingip_v2.lb_floating_ip.address}:5001|g\" /app/scripts.js" >> /usr/local/bin/restart-frontend.sh && chmod +x /usr/local/bin/restart-frontend.sh && /usr/local/bin/restart-frontend.sh && echo "Frontend container restarted and configured with load balancer IP ${openstack_networking_floatingip_v2.lb_floating_ip.address}" >> /var/log/app-setup.log
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

# Create a separate security group for monitoring instance
resource "openstack_networking_secgroup_v2" "monitoring_secgroup" {
  name        = "monitoring-secgroup"
  description = "Security group for monitoring instance"
}

# Basic rules (SSH, HTTP, HTTPS outbound)
resource "openstack_networking_secgroup_rule_v2" "monitoring_ssh" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 22
  port_range_max   = 22
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "monitoring_https_outbound" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 443
  port_range_max   = 443
  remote_ip_prefix = "0.0.0.0/0"
}

# Allow all outbound traffic for Docker and monitoring
resource "openstack_networking_secgroup_rule_v2" "monitoring_all_outbound" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "egress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_ip_prefix = "0.0.0.0/0"
}

# Monitoring specific ports (ingress)
resource "openstack_networking_secgroup_rule_v2" "monitoring_grafana" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 3000
  port_range_max   = 3000
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "monitoring_prometheus" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9090
  port_range_max   = 9090
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "monitoring_node_exporter" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 9100
  port_range_max   = 9100
  remote_ip_prefix = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "monitoring_cadvisor" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 8081
  port_range_max   = 8081
  remote_ip_prefix = "0.0.0.0/0"
}

# Allow internal network communication
resource "openstack_networking_secgroup_rule_v2" "monitoring_internal" {
  security_group_id = openstack_networking_secgroup_v2.monitoring_secgroup.id
  direction         = "ingress"
  ethertype        = "IPv4"
  protocol         = "tcp"
  port_range_min   = 1
  port_range_max   = 65535
  remote_ip_prefix = "192.168.255.0/24"  # Your subnet CIDR
}

# Create a dedicated port for the monitoring instance
resource "openstack_networking_port_v2" "monitoring_port" {
  name               = "monitoring-port"
  network_id         = openstack_networking_network_v2.terraform_network.id
  security_group_ids = [openstack_networking_secgroup_v2.monitoring_secgroup.id]
  admin_state_up     = true

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.terraform_subnet.id
  }
}

# Update the monitoring instance to use the new security group
resource "openstack_compute_instance_v2" "monitoring_instance" {
  name              = "monitoring-instance"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = data.openstack_compute_keypair_v2.terraform_keypair.name
  security_groups   = [openstack_networking_secgroup_v2.monitoring_secgroup.name]

  network {
    port = openstack_networking_port_v2.monitoring_port.id
  }

  # Add a metadata tag for easier identification
  metadata = {
    role = "monitoring"
  }

  # Update the user_data script to include error checking
  user_data = <<-EOT
    #!/bin/bash
    
    # Log file for installation progress
    LOGFILE="/var/log/monitoring-setup.log"
    
    echo "Starting monitoring setup at $(date)" > $LOGFILE
    
    # Update and install required packages
    echo "Updating package lists..." >> $LOGFILE
    apt-get update >> $LOGFILE 2>&1
    
    echo "Installing required packages..." >> $LOGFILE
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common \
      gnupg \
      lsb-release \
      docker.io \
      docker-compose >> $LOGFILE 2>&1
    
    # Add current user to docker group
    usermod -aG docker ubuntu
    
    # Create monitoring directory structure
    echo "Creating directory structure..." >> $LOGFILE
    mkdir -p /opt/monitoring/prometheus
    mkdir -p /opt/monitoring/grafana/provisioning/datasources
    mkdir -p /opt/monitoring/grafana/provisioning/dashboards
    mkdir -p /opt/monitoring/grafana/dashboards
    
    # Create docker-compose.yml
    echo "Creating docker-compose.yml..." >> $LOGFILE
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
          - GF_INSTALL_PLUGINS=
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
          - "8081:8080"  # Map container's 8080 to host's 8081
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
    echo "Creating Prometheus configuration..." >> $LOGFILE
    cat > /opt/monitoring/prometheus/prometheus.yml << EOF
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      
      - job_name: 'node-exporter'
        static_configs:
          - targets: 
              - 'node-exporter:9100'
              - '${openstack_compute_instance_v2.docker_instances[0].access_ip_v4}:9100'
              - '${openstack_compute_instance_v2.docker_instances[1].access_ip_v4}:9100'
              - '${openstack_compute_instance_v2.docker_instances[2].access_ip_v4}:9100'
      
      - job_name: 'cadvisor'
        static_configs:
          - targets: ['cadvisor:8080']
      
      - job_name: 'application'
        metrics_path: '/metrics'
        static_configs:
          - targets: 
              - '${openstack_compute_instance_v2.docker_instances[0].access_ip_v4}:8080'
              - '${openstack_compute_instance_v2.docker_instances[1].access_ip_v4}:8080'
              - '${openstack_compute_instance_v2.docker_instances[2].access_ip_v4}:8080'
    EOF
    
    # Create Grafana datasource
    echo "Creating Grafana datasource..." >> $LOGFILE
    cat > /opt/monitoring/grafana/provisioning/datasources/prometheus.yml << EOF
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
    EOF
    
    # Create Grafana dashboard provisioning config
    echo "Creating Grafana dashboard provisioning config..." >> $LOGFILE
    cat > /opt/monitoring/grafana/provisioning/dashboards/default.yml << EOF
    apiVersion: 1
    providers:
      - name: 'Default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        updateIntervalSeconds: 10
        allowUiUpdates: true
        options:
          path: /var/lib/grafana/dashboards
    EOF
    
    # Create System Metrics Dashboard
    echo "Creating Grafana dashboard for system metrics..." >> $LOGFILE
    cat > /opt/monitoring/grafana/dashboards/system_metrics.json << 'EOF'
    {
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "grafana",
              "uid": "-- Grafana --"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          }
        ]
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "id": null,
      "links": [],
      "liveNow": false,
      "panels": [
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 0
          },
          "id": 12,
          "panels": [],
          "title": "CPU Usage",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "percent"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 24,
            "x": 0,
            "y": 1
          },
          "id": 1,
          "options": {
            "legend": {
              "calcs": [
                "mean",
                "max"
              ],
              "displayMode": "table",
              "placement": "right",
              "showLegend": true
            },
            "tooltip": {
              "mode": "multi",
              "sort": "none"
            }
          },
          "targets": [
            {
              "datasource": {
                "type": "prometheus",
                "uid": "PBFA97CFB590B2093"
              },
              "editorMode": "code",
              "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) * 100)",
              "legendFormat": "{{instance}}",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "CPU Usage by Instance",
          "type": "timeseries"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 9
          },
          "id": 13,
          "panels": [],
          "title": "Memory Usage",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "percent"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 24,
            "x": 0,
            "y": 10
          },
          "id": 2,
          "options": {
            "legend": {
              "calcs": [
                "mean",
                "max"
              ],
              "displayMode": "table",
              "placement": "right",
              "showLegend": true
            },
            "tooltip": {
              "mode": "multi",
              "sort": "none"
            }
          },
          "targets": [
            {
              "datasource": {
                "type": "prometheus",
                "uid": "PBFA97CFB590B2093"
              },
              "editorMode": "code",
              "expr": "100 * (1 - ((node_memory_MemFree_bytes + node_memory_Cached_bytes + node_memory_Buffers_bytes) / node_memory_MemTotal_bytes))",
              "legendFormat": "{{instance}}",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "Memory Usage by Instance",
          "type": "timeseries"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 18
          },
          "id": 14,
          "panels": [],
          "title": "Disk Usage",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "percent"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 24,
            "x": 0,
            "y": 19
          },
          "id": 3,
          "options": {
            "legend": {
              "calcs": [
                "mean",
                "max"
              ],
              "displayMode": "table",
              "placement": "right",
              "showLegend": true
            },
            "tooltip": {
              "mode": "multi",
              "sort": "none"
            }
          },
          "targets": [
            {
              "datasource": {
                "type": "prometheus",
                "uid": "PBFA97CFB590B2093"
              },
              "editorMode": "code",
              "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\",fstype!=\"rootfs\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/\",fstype!=\"rootfs\"})",
              "legendFormat": "{{instance}}",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "Disk Usage by Instance",
          "type": "timeseries"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 27
          },
          "id": 15,
          "panels": [],
          "title": "Disk I/O",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "Bps"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 28
          },
          "id": 4,
          "options": {
            "legend": {
              "calcs": [
                "mean",
                "max"
              ],
              "displayMode": "table",
              "placement": "bottom",
              "showLegend": true
            },
            "tooltip": {
              "mode": "multi",
              "sort": "none"
            }
          },
          "targets": [
            {
              "datasource": {
                "type": "prometheus",
                "uid": "PBFA97CFB590B2093"
              },
              "editorMode": "code",
              "expr": "rate(node_disk_read_bytes_total[1m])",
              "legendFormat": "{{instance}} - {{device}}",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "Disk Read Throughput",
          "type": "timeseries"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "drawStyle": "line",
                "fillOpacity": 10,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "never",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": null
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "Bps"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 28
          },
          "id": 5,
          "options": {
            "legend": {
              "calcs": [
                "mean",
                "max"
              ],
              "displayMode": "table",
              "placement": "bottom",
              "showLegend": true
            },
            "tooltip": {
              "mode": "multi",
              "sort": "none"
            }
          },
          "targets": [
            {
              "datasource": {
                "type": "prometheus",
                "uid": "PBFA97CFB590B2093"
              },
              "editorMode": "code",
              "expr": "rate(node_disk_written_bytes_total[1m])",
              "legendFormat": "{{instance}} - {{device}}",
              "range": true,
              "refId": "A"
            }
          ],
          "title": "Disk Write Throughput",
          "type": "timeseries"
        }
      ],
      "refresh": "10s",
      "schemaVersion": 38,
      "style": "dark",
      "tags": [],
      "templating": {
        "list": []
      },
      "time": {
        "from": "now-1h",
        "to": "now"
      },
      "timepicker": {},
      "timezone": "",
      "title": "System Metrics Dashboard",
      "uid": "system-metrics",
      "version": 1,
      "weekStart": ""
    }
    EOF
    
    # Start monitoring stack
    echo "Starting monitoring stack..." >> $LOGFILE
    cd /opt/monitoring
    docker-compose down --remove-orphans || true
    docker-compose pull
    docker-compose up -d
    
    # Log final status
    echo "Final Docker containers status:" >> $LOGFILE
    docker ps -a >> $LOGFILE
    echo "Docker Compose logs:" >> $LOGFILE
    docker-compose logs >> $LOGFILE
    
    echo "Monitoring setup completed at $(date)" >> $LOGFILE
  EOT
}

# Create floating IP for monitoring instance
resource "openstack_networking_floatingip_v2" "monitoring_floating_ip" {
  pool    = local.pubnet_name
  port_id = openstack_networking_port_v2.monitoring_port.id
}

# Output monitoring URLs
output "monitoring_urls" {
  value = {
    grafana    = "http://${openstack_networking_floatingip_v2.monitoring_floating_ip.address}:3000"
    prometheus = "http://${openstack_networking_floatingip_v2.monitoring_floating_ip.address}:9090"
  }
}

# Output application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${openstack_networking_floatingip_v2.lb_floating_ip.address}:8080"
}