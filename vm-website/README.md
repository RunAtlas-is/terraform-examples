# VM Website Example

Deploy a website on Atlas Cloud with Terraform. Supports both HTTP (no domain) and HTTPS (with Let's Encrypt via Traefik).

![Website Screenshot](./screenshot.png)

> **Note:** Add your screenshot as `screenshot.png` in the `vm-website/` directory

## Quick Start

```bash
# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your CloudStack credentials
# Required: cloudstack_api_url, cloudstack_api_key, cloudstack_secret_key
# Required: ssh_public_key
vim terraform.tfvars

# Deploy
terraform init
terraform apply

# Get the URL
terraform output website_url
```

### Example Configuration

```hcl
# CloudStack Configuration
cloudstack_api_url    = "https://sky.runatlas.is/client/api"
cloudstack_api_key    = "your-api-key"
cloudstack_secret_key = "your-secret-key"

# SSH Access
ssh_public_key = "ssh-rsa AAAA..."

# Infrastructure (use these values for Atlas Cloud)
zone                      = "is1"
instance_service_offering = "Atlas.a4"
instance_template         = "Ubuntu 24.04 LTS"
network_offering          = "DefaultIsolatedNetworkOfferingWithSourceNatService"

# HTTPS Configuration (leave empty for HTTP-only)
domain_name   = ""
email_address = ""
```

## Configuration

Edit `terraform.tfvars` with your settings:

- **HTTP-only**: Leave `domain_name` empty
- **HTTPS**: Set `domain_name` and `email_address`, then configure DNS

## DNS Setup (HTTPS only)

After deployment, point your domain's A record to the output IP:

```bash
terraform output webserver_public_ip
```

## Cleanup

```bash
terraform destroy
```

## Deployment Example

Successfully deployed example running at: **http://149.126.81.28/**

### What Gets Created

- **Network:** Isolated network with egress firewall rules
- **VM:** Ubuntu 24.04 LTS with cloud-init setup
- **Public IP:** Static IP with port forwarding (HTTP 80, SSH 22)
- **Firewall:** Ingress rules for HTTP and SSH access

### Known Issues

**Egress Firewall:** The current configuration may prevent package installation from external repositories. The example uses a workaround (Python HTTP server) for demonstration. For production use, review and adjust egress firewall rules as needed.

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Infrastructure (network, VM, firewall) |
| `variables.tf` | Input variables |
| `cloud-init-http.yaml` | HTTP setup (nginx) |
| `cloud-init-https.yaml` | HTTPS setup (traefik + nginx) |
| `terraform.tfvars.example` | Example configuration |
