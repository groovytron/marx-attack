# Define required providers
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.52.1"
    }
  }
}

data "external" "env" {
  program = ["${path.module}/env.sh"]
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key to add to the instance"
}

# Configure the OpenStack Provider
provider "openstack" {
  auth_url = data.external.env.result["os_auth_url"]
  region = data.external.env.result["os_region"]
  user_name = data.external.env.result["os_user_name"]
  password = data.external.env.result["os_password"]
  user_domain_name = data.external.env.result["os_user_domain_name"]
  project_domain_id = data.external.env.result["os_project_domain_id"]
  tenant_id = data.external.env.result["os_tenant_id"]
  tenant_name = data.external.env.result["os_tenant_name"]
}

# Upload public key
resource "openstack_compute_keypair_v2" "mpoy_key_pair" {
  name = "mpoy_key_pair"
  public_key = var.ssh_public_key
}

# Create a web security group
resource "openstack_compute_secgroup_v2" "MarxAttackWeb" {
  name        = "security_group_name"
  description = "Marx Attack Webserver (22 - 80 - 443)"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Create a web server
resource "openstack_compute_instance_v2" "web-server" {
  name            = "web-server"
  image_id        = "image_id"
  flavor_name     = "7918af3e-aa2a-4aa4-976d-9056490a4654"
  key_pair        = "mpoy_key_pair"
  security_groups = ["MarxAttackWeb"]

  metadata = {
    application = "web-app"
  }

  network {
    name = "ext-net1"
  }
}
