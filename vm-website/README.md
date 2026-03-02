# VM Website Example

Deploy a website on Atlas Cloud with Terraform. Supports both HTTP (no domain) and HTTPS (with Let's Encrypt via Traefik).

## Quick Start

```bash
# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Deploy
terraform init
terraform apply

# Get the URL
terraform output website_url
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

## Files

| File | Purpose |
|------|---------|
| `main.tf` | Infrastructure (network, VM, firewall) |
| `variables.tf` | Input variables |
| `cloud-init-http.yaml` | HTTP setup (nginx) |
| `cloud-init-https.yaml` | HTTPS setup (traefik + nginx) |
| `terraform.tfvars.example` | Example configuration |
