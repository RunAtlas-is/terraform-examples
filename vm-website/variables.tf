variable "cloudstack_api_url" {
  type        = string
  sensitive   = true
  description = "CloudStack API URL"
}

variable "cloudstack_api_key" {
  type        = string
  sensitive   = true
  description = "CloudStack API key"
}

variable "cloudstack_secret_key" {
  type        = string
  sensitive   = true
  description = "CloudStack secret key"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for server access"
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Domain name for SSL (leave empty for HTTP-only)"
}

variable "email_address" {
  type        = string
  default     = ""
  description = "Email for Let's Encrypt (required if domain_name is set)"
}

variable "zone" {
  type        = string
  default     = "is1"
  description = "Atlas Cloud zone"
}

variable "instance_service_offering" {
  type        = string
  default     = "Atlas.a4"
  description = "VM instance size (Atlas.a4 = 2 vCPU, 4GB RAM, 20GB disk)"
}

variable "instance_template" {
  type        = string
  default     = "Ubuntu 24.04 LTS"
  description = "VM OS template"
}

variable "network_offering" {
  type        = string
  default     = "DefaultIsolatedNetworkOfferingWithSourceNatService"
  description = "Network offering type (use DefaultIsolatedNetworkOfferingWithSourceNatService for Atlas Cloud)"
}

variable "ssh_allowed_ips" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "IP ranges allowed to SSH"
}
