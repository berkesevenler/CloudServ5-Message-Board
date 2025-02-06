variable "auth_url"         { type = string }
variable "user_name"        { type = string }
variable "user_password"    { type = string }
variable "tenant_name"      { type = string }
variable "project_id"       { type = string }
variable "user_domain_name" { type = string }
variable "cacert_file"      { type = string }
variable "region_name"      { type = string }
variable "router_name"      { type = string }
variable "pubnet_name"      { type = string }
variable "image_name"       { type = string }
variable "flavor_name"      { type = string }
variable "key_pair"         { type = string }
variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}
variable "instance_count" {
  type    = number
  default = 3
}
