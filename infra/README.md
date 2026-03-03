# NoFlame Infrastructure

Terraform configuration to deploy NoFlame on Oracle Cloud (OCI).

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
- An [Oracle Cloud account](https://www.oracle.com/cloud/free/)
- An OCI API key (`~/.oci/oci_api_key.pem`)

## Setup

1. Copy and fill in your OCI credentials:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Deploy:
```bash
terraform init
terraform plan
terraform apply
```

3. Tear down:
```bash
terraform destroy
```

## Files

```
infra/
├── main.tf                  # VCN, compute, object storage
├── variables.tf             # OCI auth and project variables
├── outputs.tf               # Backend IP, frontend URL
├── providers.tf             # OCI provider config
├── versions.tf              # Terraform version requirements
├── user_data.sh             # Oracle Linux bootstrap script
├── terraform.tfvars.example # Template config
└── .gitignore               # Ignores tfvars, tfstate, .terraform/
```

## Troubleshooting

**"Out of capacity" error** — Switch to `VM.Standard.E2.1.Micro` in terraform.tfvars

**Can't SSH** — Check your IP is in `allowed_ssh_cidrs` and wait 1-2 min after launch

**Backend won't start** — Check logs:
```bash
ssh opc@BACKEND_IP 'sudo journalctl -u noflame -n 50'
ssh opc@BACKEND_IP 'cat /var/log/user-data.log'
```

**Firewall blocking ports** — Verify with:
```bash
ssh opc@BACKEND_IP 'sudo firewall-cmd --list-all'
```
