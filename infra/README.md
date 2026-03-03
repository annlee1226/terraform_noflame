# NoFlame Infrastructure - Oracle Cloud (OCI)

Terraform configuration to deploy NoFlame on Oracle Cloud Always Free Tier.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Oracle Cloud (OCI)                           │
│                                                                  │
│   ┌──────────────────┐              ┌─────────────────────────┐ │
│   │ Object Storage   │              │  Ampere A1 Compute      │ │
│   │   (Frontend)     │   ──────►    │  Flask + TensorFlow     │ │
│   │                  │   API calls  │  ML Fire Detection      │ │
│   │   React App      │              │  1 OCPU, 6GB RAM        │ │
│   └──────────────────┘              └─────────────────────────┘ │
│          │                                    │                  │
│          ▼                                    ▼                  │
│   Object Storage URL               Compute Public IP:5001       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Why OCI Always Free?

Oracle Cloud offers a **permanently free tier** (not just 12 months):

| Resource | Always Free Limit |
|----------|-------------------|
| Ampere A1 Compute | 4 OCPUs, 24GB RAM (total) |
| Block Storage | 200GB |
| Object Storage | 20GB |
| Outbound Data | 10TB/month |

This is **significantly more powerful** than AWS free tier, and it **never expires**.

---

## Prerequisites

1. **OCI Account** - [Sign up for Always Free](https://www.oracle.com/cloud/free/)
2. **OCI CLI** - [Install guide](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
3. **Terraform** - [Install guide](https://developer.hashicorp.com/terraform/install)
4. **API Key** - Generate in OCI Console

---

## Quick Start

### 1. Create OCI API Key

1. Log in to [OCI Console](https://cloud.oracle.com)
2. Click your profile icon → **User Settings**
3. Under **API Keys**, click **Add API Key**
4. Choose **Generate API Key Pair**
5. Download the private key to `~/.oci/oci_api_key.pem`
6. Copy the **Configuration File Preview** - you'll need these values

```bash
chmod 600 ~/.oci/oci_api_key.pem
```

### 2. Get Your OCIDs

From OCI Console:
- **Tenancy OCID**: Profile icon → Tenancy → Copy OCID
- **User OCID**: Profile icon → User Settings → Copy OCID
- **Compartment OCID**: Identity → Compartments → Copy OCID (use root compartment or create one)

### 3. Create terraform.tfvars

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..xxxxx"
user_ocid        = "ocid1.user.oc1..xxxxx"
fingerprint      = "aa:bb:cc:dd:..."
private_key_path = "~/.oci/oci_api_key.pem"
compartment_ocid = "ocid1.compartment.oc1..xxxxx"
region           = "us-ashburn-1"

# Your SSH public key (contents of ~/.ssh/id_rsa.pub)
ssh_public_key = "ssh-rsa AAAA..."

# Your IP for SSH access
allowed_ssh_cidrs = ["YOUR_IP/32"]
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply   # Type 'yes' to confirm
```

### 5. Update Frontend Config

Create `Frontend/vite-project/.env`:
```bash
VITE_API_URL=http://COMPUTE_IP:5001
```

### 6. Build and Deploy Frontend

```bash
cd Frontend/vite-project
npm install
npm run build

# Upload to OCI Object Storage
oci os object bulk-upload \
  --bucket-name $(cd ../../infra && terraform output -raw frontend_bucket_name) \
  --src-dir dist \
  --overwrite
```

### 7. Deploy Backend

```bash
# Copy backend code to compute instance
scp -r Backend/* opc@COMPUTE_IP:/opt/noflame/

# SSH and start service
ssh opc@COMPUTE_IP
sudo systemctl start noflame
sudo systemctl status noflame
```

### 8. Test

- **Backend**: `curl http://COMPUTE_IP:5001/fireAlarm`
- **Frontend**: Use the `frontend_url` from terraform output

---

## Teardown

```bash
terraform destroy   # Type 'yes' to confirm
```

---

## Cost: $0

All resources stay within OCI Always Free limits:
- 1 Ampere A1 instance (1 OCPU, 6GB RAM)
- 50GB boot volume
- Object Storage bucket
- 10.0.0.0/16 VCN

**No time limit** - these resources are free forever.

---

## Files

```
infra/
├── main.tf                  # VCN, compute, object storage
├── variables.tf             # OCI-specific variables
├── outputs.tf               # URLs and deployment commands
├── providers.tf             # OCI provider config
├── versions.tf              # Terraform version requirements
├── user_data.sh             # Oracle Linux bootstrap script
├── terraform.tfvars.example # Example configuration
└── README.md                # This file
```

---

## Troubleshooting

### "Out of capacity" error for A1 shapes
Ampere A1 instances are popular. Try:
- Different availability domain
- Different region (us-phoenix-1, uk-london-1)
- Wait and retry later

### Can't SSH to instance
1. Check security list allows your IP on port 22
2. Verify SSH key is correct
3. Check instance is running: `oci compute instance get --instance-id <OCID>`

### Backend won't start
```bash
ssh opc@COMPUTE_IP
sudo journalctl -u noflame -f
cat /var/log/user-data.log
```

### Firewall blocking ports
Oracle Linux uses firewalld. The user_data script opens ports, but verify:
```bash
sudo firewall-cmd --list-all
```

---

## OCI vs AWS Comparison

| Feature | OCI Always Free | AWS Free Tier |
|---------|----------------|---------------|
| Duration | **Forever** | 12 months |
| Compute | 4 OCPUs, 24GB RAM | 750 hrs t2.micro |
| Storage | 200GB block | 30GB EBS |
| Data Transfer | 10TB/month | 100GB/month |
| Best For | Production workloads | Learning/testing |
