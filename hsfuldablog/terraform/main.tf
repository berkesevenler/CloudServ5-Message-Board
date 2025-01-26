provider "openstack" {
  auth_url    = "https://<openstack-api-url>/v3"
  username    = "<your-username>"
  password    = "<your-password>"
  tenant_name = "<your-tenant-name>"
  region      = "RegionOne"
}

resource "openstack_compute_instance_v2" "frontend" {
  name            = "frontend-server"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-20.04"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["default"]

  network {
    name = "private-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install docker.io -y",
      "docker run -d -p 80:80 <frontend-docker-image>"
    ]
  }
}

resource "openstack_compute_instance_v2" "backend" {
  name            = "backend-server"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-20.04"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["default"]

  network {
    name = "private-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install docker.io -y",
      "docker run -d -p 5000:5000 <backend-docker-image>"
    ]
  }
}

resource "openstack_compute_instance_v2" "database" {
  name            = "database-server"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-20.04"
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = ["default"]

  network {
    name = "private-network"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install docker.io -y",
      "docker run -d -p 5432:5432 <database-docker-image>"
    ]
  }
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "message-board-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
