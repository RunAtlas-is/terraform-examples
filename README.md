# Terraform Examples for Atlas Cloud

A collection of Terraform examples for deploying infrastructure on [Atlas Cloud](https://runatlas.is).

## Examples

| Example | Description | Difficulty |
|---------|-------------|------------|
| [vm-website](./vm-website) | Deploy a website on a VM with HTTP or HTTPS (Let's Encrypt via Traefik) | 🟢 Beginner |

## Quick Start

All examples are **plug-and-play** - just add your credentials:

```bash
# Clone the repository
git clone https://github.com/RunAtlas-is/terraform-examples.git
cd terraform-examples/vm-website

# Configure your credentials (only 3 required fields)
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy
terraform init
terraform apply
```

## Prerequisites

- [Terraform](https://terraform.io) >= 1.0
- Atlas Cloud account with API access
- SSH key pair

## Getting API Credentials

1. Log in to [sky.runatlas.is](https://sky.runatlas.is)
2. Click your profile (top-right corner)
3. Copy your **API Key** and **Secret Key**

## Documentation

Full documentation available at [docs.runatlas.is](https://docs.runatlas.is)

## License

MIT
