
variable "auth_url" {
  type    = string
  description = "The authentication URL for OpenStack"
  default = "https://private-cloud.informatik.hs-fulda.de:5000/v3"
}

variable "user_name" {
  type    = string
  description = "The username for OpenStack"
  default = "CloudServ5"
}

variable "user_password" {
  type    = string
  description = "The password for OpenStack"
  default = "demo"
}

variable "tenant_name" {
  type    = string
  description = "The tenant name for OpenStack"
  default = "CloudServ5"
}

variable "project_id" {
  type    = string
  description = "The project ID for OpenStack"
  default = "42df268bf0cb4cc29c7df8a6db120545"
}

variable "user_domain_name" {
  type    = string
  description = "The user domain name for OpenStack"
  default = "default"
}

variable "cacert_file" {
  type    = string
  description = "The path to the CA certificate file"
  default = "./os-trusted-cas"
}

variable "region_name" {
  type    = string
  description = "The region name for OpenStack"
  default = "RegionOne"
}

variable "router_name" {
  type    = string
  description = "The router name for OpenStack"
  default = "CloudServ5-router"
}

variable "dns_servers" {
  type    = list(string)
  description = "List of DNS servers"
  default = ["10.33.16.100", "8.8.8.8"]
}

variable "pubnet_name" {
  type    = string
  description = "The public network name"
  default = "ext_net"
}

variable "image_name" {
  type    = string
  description = "The name of the image to use for instances"
  default = "ubuntu-22.04-jammy-server-cloud-image-amd64"
}

variable "flavor_name" {
  type    = string
  description = "The flavor to use for instances"
  default = "m1.small"
}

variable "docker_image_name" {
  type    = string
  default = "Ubuntu 20.04"
  description = "The Docker image name"
}

variable "docker_flavor_name" {
  type    = string
  default = "m1.small"
  description = "The flavor for the Docker instance"
}

variable "key_pair" {
  type    = string
  description = "The name of the key pair to use"
  default = "CloudServ5-key"
}

variable "docker_network_name" {
  type    = string
  default = "docker-network"
  description = "The name of the Docker network"
}

variable "docker_subnet_cidr" {
  type    = string
  default = "192.168.1.0/24"
  description = "The CIDR for the Docker subnet"
}

variable "docker_gateway_ip" {
  type    = string
  default = "192.168.1.1"
  description = "The gateway IP for the Docker subnet"
}

variable "docker_router_name" {
  type    = string
  default = "docker-router"
  description = "The name of the Docker router"
}

variable "docker_secgroup_name" {
  type    = string
  default = "docker-secgroup"
  description = "The name of the Docker security group"
}
