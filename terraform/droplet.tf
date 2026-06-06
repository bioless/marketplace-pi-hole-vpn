terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.3.0"
}

# Variable values: set in terraform.tfvars or via -var="..." CLI option.
# Never commit terraform.tfvars — it contains the DO API token.
variable "do_token" {
  type      = string
  sensitive = true
}

# Snapshot image ID from Packer output
variable "image" {
  type = string
}

# List of DigitalOcean SSH key IDs to install on the Droplet
variable "ssh_keys" {
  type = list(number)
}

# DigitalOcean region (nyc1 by default; change to a region closer to you)
variable "region" {
  type    = string
  default = "nyc1"
}

# Droplet size — 1 vCPU, 1GB RAM is sufficient for Pi-hole + WireGuard.
# The 512MB tier can run all services but may be memory-constrained under load.
variable "size" {
  type    = string
  default = "s-1vcpu-1gb"
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "pihole_vpn" {
  # Do not install the DigitalOcean agent — reduces fingerprint and attack surface
  droplet_agent = false

  image   = var.image
  # IPv6 is enabled; WireGuard handles both IPv4 and IPv6 tunneling
  ipv6    = true
  # Monitoring agent is disabled — use external monitoring if needed
  monitoring = false

  # Neutral name that does not reveal the server's purpose
  name    = "privacy-node"
  region  = var.region
  size    = var.size

  ssh_keys = var.ssh_keys
}

output "droplet_ipv4" {
  value       = digitalocean_droplet.pihole_vpn.ipv4_address
  description = "Public IPv4 address of the Droplet"
}

output "droplet_ipv6" {
  value       = digitalocean_droplet.pihole_vpn.ipv6_address
  description = "Public IPv6 address of the Droplet"
}
