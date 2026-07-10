terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "0.6.0"
    }
  }
  required_version = ">=1.0.0"
}

provider "cloudstack" {
  api_url    = var.cloudstack_api_url
  api_key    = var.cloudstack_api_key
  secret_key = var.cloudstack_secret_key
}

resource "cloudstack_network" "webserver_network" {
  name             = "webserver-network-v2"
  cidr             = "10.1.0.0/24"
  network_offering = var.network_offering
  zone             = var.zone
}

resource "cloudstack_instance" "webserver" {
  name             = "webserver-vm-${formatdate("YYYYMMDD-hhmm", timestamp())}"
  service_offering = var.instance_service_offering
  template         = var.instance_template
  zone             = var.zone
  network_id       = cloudstack_network.webserver_network.id

  user_data = var.domain_name != "" ? templatefile("${path.module}/cloud-init-https.yaml", {
    ssh_public_key = var.ssh_public_key
    domain_name    = var.domain_name
    email_address  = var.email_address
    }) : templatefile("${path.module}/cloud-init-http.yaml", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "cloudstack_ipaddress" "webserver_ip" {
  network_id = cloudstack_network.webserver_network.id
}

resource "cloudstack_port_forward" "webserver_ports" {
  for_each = var.domain_name != "" ? {
    http  = 80
    https = 443
    ssh   = 22
    } : {
    http = 80
    ssh  = 22
  }

  ip_address_id = cloudstack_ipaddress.webserver_ip.id
  forward {
    protocol           = "tcp"
    public_port        = each.value
    private_port       = each.value
    virtual_machine_id = cloudstack_instance.webserver.id
  }
}

resource "cloudstack_firewall" "ingress" {
  ip_address_id = cloudstack_ipaddress.webserver_ip.id
  managed       = true # Automatically manage all firewall rules for this IP

  rule {
    protocol  = "tcp"
    ports     = ["80"]
    cidr_list = ["0.0.0.0/0"]
  }

  dynamic "rule" {
    for_each = var.domain_name != "" ? [1] : []
    content {
      protocol  = "tcp"
      ports     = ["443"]
      cidr_list = ["0.0.0.0/0"]
    }
  }

  rule {
    protocol  = "tcp"
    ports     = ["22"]
    cidr_list = var.ssh_allowed_ips
  }
}

resource "cloudstack_egress_firewall" "egress" {
  network_id = cloudstack_network.webserver_network.id
  managed    = true # Automatically manage all egress firewall rules for this network

  rule {
    protocol  = "tcp"
    ports     = ["80"]
    cidr_list = ["0.0.0.0/0"]
  }

  rule {
    protocol  = "tcp"
    ports     = ["443"]
    cidr_list = ["0.0.0.0/0"]
  }

  rule {
    protocol  = "udp"
    ports     = ["53"]
    cidr_list = ["0.0.0.0/0"]
  }

  rule {
    protocol  = "tcp"
    ports     = ["53"]
    cidr_list = ["0.0.0.0/0"]
  }
}

output "webserver_public_ip" {
  value = cloudstack_ipaddress.webserver_ip.ip_address
}

output "website_url" {
  value = var.domain_name != "" ? "https://${var.domain_name}/" : "http://${cloudstack_ipaddress.webserver_ip.ip_address}/"
}
