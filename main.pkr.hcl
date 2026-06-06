packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.4.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

variable "do_token" {
  type      = string
  sensitive = true
}

# Number of WireGuard client configs to pre-generate (shown in motd on first boot)
variable "wg_client_count" {
  type    = number
  default = 1
}

# WireGuard listen port. Default 51820. Alternatives: 443 (UDP), 53 (UDP).
variable "wg_port" {
  type    = number
  default = 51820
}

source "digitalocean" "bookworm" {
  api_token     = var.do_token
  droplet_agent = false
  image         = "debian-12-x64"
  monitoring    = false
  region        = "nyc1"
  size          = "s-1vcpu-512mb-10gb"
  ssh_username  = "root"
  snapshot_name = "marketplace-pi-hole-vpn-{{timestamp}}"
}

build {
  sources = [
    "source.digitalocean.bookworm"
  ]

  # Harden the base image at build time: update packages, configure ufw,
  # apply sysctl settings, install unattended-upgrades.
  provisioner "shell" {
    scripts = [
      "scripts/system-setup.sh",
    ]
  }

  # Deploy cloud-init per-instance scripts. These run in numbered order on
  # every fresh Droplet boot. The per-instance directory runs only once per
  # new instance (not on every reboot).

  # 01 — system setup (same as build-time, idempotent)
  provisioner "file" {
    source      = "scripts/system-setup.sh"
    destination = "/tmp/system-setup.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "mv /tmp/system-setup.sh /var/lib/cloud/scripts/per-instance/01-setup-system.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/01-setup-system.sh",
    ]
  }

  # 02 — WireGuard install and key generation
  provisioner "file" {
    source      = "scripts/wg-setup.sh"
    destination = "/tmp/wg-setup.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "cp /tmp/wg-setup.sh /var/lib/cloud/scripts/per-instance/02-setup-wireguard.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/02-setup-wireguard.sh",
      "mv /tmp/wg-setup.sh /root/regen-vpn-keys.sh",
      "chmod 700 /root/regen-vpn-keys.sh",
    ]
  }

  # 03 — Pi-hole v6 installation and configuration
  provisioner "file" {
    source      = "scripts/pihole-setup.sh"
    destination = "/tmp/pihole-setup.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "mv /tmp/pihole-setup.sh /var/lib/cloud/scripts/per-instance/03-setup-pihole.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/03-setup-pihole.sh",
    ]
  }

  # 04 — Unbound recursive DNS resolver
  provisioner "file" {
    source      = "scripts/unbound-setup.sh"
    destination = "/tmp/unbound-setup.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "mv /tmp/unbound-setup.sh /var/lib/cloud/scripts/per-instance/04-setup-unbound.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/04-setup-unbound.sh",
    ]
  }

  # 05 — SSH hardening, fail2ban, and service cleanup
  provisioner "file" {
    source      = "scripts/security-setup.sh"
    destination = "/tmp/security-setup.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "mv /tmp/security-setup.sh /var/lib/cloud/scripts/per-instance/05-setup-security.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/05-setup-security.sh",
    ]
  }

  # 09 — SSH unlock (runs last; number chosen to run after all setup scripts)
  provisioner "file" {
    source      = "scripts/ssh-unlock.sh"
    destination = "/tmp/ssh-unlock.sh"
  }
  provisioner "shell" {
    inline = [
      "mkdir -p /var/lib/cloud/scripts/per-instance/",
      "mv /tmp/ssh-unlock.sh /var/lib/cloud/scripts/per-instance/09-unlock-ssh.sh",
      "chmod 700 /var/lib/cloud/scripts/per-instance/09-unlock-ssh.sh",
    ]
  }

  # Peer management helper: add new WireGuard peers without manual wg commands
  provisioner "file" {
    source      = "scripts/add-vpn-peer.sh"
    destination = "/root/add-vpn-peer.sh"
  }
  provisioner "shell" {
    inline = ["chmod 700 /root/add-vpn-peer.sh"]
  }

  # Finalize: clean up the image and run the DigitalOcean marketplace validator
  provisioner "shell" {
    scripts = [
      "scripts/image-cleanup.sh",
      "scripts/ssh-lock.sh",
      "scripts/image-check.sh",
    ]
  }
}
