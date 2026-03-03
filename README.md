# NoFlame

## Table of Contents

  - [Team Members](#team-members)
  - [Deployment Guide](#deployment-guide)
  - [Inspiration](#inspiration)
  - [What it does](#purpose)
  - [Build Process](#build-process)
  - [Challenges](#challenges)
  - [Accomplishments](#accomplishments)
  - [What's next for NoFlame](#next-up)


## Team Members

Jason Boenjamin, Sneha Gurung, Falak Tulsi, Anna Lee


## Deployment Guide

NoFlame is deployed on **Oracle Cloud Infrastructure (OCI)** using Terraform. The backend runs on an Always Free compute instance and the frontend is served from OCI Object Storage.

### Architecture

```
                         Oracle Cloud (OCI)
  ┌──────────────────────────────────────────────────────────┐
  │                                                          │
  │   Object Storage Bucket          Compute Instance        │
  │   ┌──────────────────┐       ┌────────────────────────┐  │
  │   │  React/Vite App  │──────>│  Flask + Gunicorn      │  │
  │   │  (Static Files)  │ :5001 │  TensorFlow ML Model   │  │
  │   └──────────────────┘       │  Oracle Linux 8        │  │
  │                              │  VM.Standard.E2.1.Micro│  │
  │                              └────────────────────────┘  │
  │                                                          │
  │   VCN: 10.0.0.0/16  |  Ports: 80, 443, 5001, 22 (SSH)  │
  └──────────────────────────────────────────────────────────┘
```

### Why Oracle Cloud?

Oracle Cloud offers an **Always Free tier that never expires** (unlike AWS's 12-month free tier):

| Resource | Always Free Limit |
|----------|-------------------|
| AMD Micro VMs | 2 instances (1/8 OCPU, 1GB RAM each) |
| Block Storage | 200GB |
| Object Storage | 20GB |
| Outbound Data | 10TB/month |

No auto-charges. You must manually upgrade to a paid account.

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) (`brew install terraform`)
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) (`brew install oci-cli`)
- [Node.js](https://nodejs.org/) (`brew install node`)
- An [Oracle Cloud account](https://www.oracle.com/cloud/free/) (free signup, temporary $1 hold refunded)

### Step 1: OCI Account and API Key

1. Sign up at [oracle.com/cloud/free](https://www.oracle.com/cloud/free/)
2. In [OCI Console](https://cloud.oracle.com), go to **Profile** > **User Settings** > **API Keys** > **Add API Key**
3. Download the private key to `~/.oci/oci_api_key.pem`
4. Note your Tenancy OCID, User OCID, and Fingerprint from the configuration preview

```bash
chmod 600 ~/.oci/oci_api_key.pem
```

### Step 2: Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "noflame" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub    # Copy this for terraform.tfvars
curl ifconfig.me             # Get your IP for SSH access
```

### Step 3: Configure Terraform

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your OCI values:
```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..xxxxx"
user_ocid        = "ocid1.user.oc1..xxxxx"
fingerprint      = "aa:bb:cc:dd:ee:ff:..."
private_key_path = "~/.oci/oci_api_key.pem"
region           = "us-sanjose-1"
compartment_ocid = "ocid1.tenancy.oc1..xxxxx"   # Use tenancy OCID for root compartment

ssh_public_key    = "ssh-ed25519 AAAAC3Nza... noflame"
allowed_ssh_cidrs = ["YOUR_IP/32"]
instance_shape    = "VM.Standard.E2.1.Micro"
```

> `terraform.tfvars` is gitignored — it contains credentials.

### Step 4: Deploy Infrastructure

```bash
terraform init    # Download OCI provider
terraform plan    # Preview resources
terraform apply   # Deploy (type 'yes')
```

This creates: VCN, subnet, internet gateway, security list, object storage bucket, and a compute instance. The instance automatically runs `user_data.sh` on boot which installs Python 3.11, TensorFlow, Flask, and sets up a systemd service.

Wait ~10-15 minutes for the bootstrap to complete. Monitor with:
```bash
ssh opc@BACKEND_IP 'tail -f /var/log/user-data.log'
```

### Step 5: Deploy Backend

```bash
scp Backend/app.py opc@BACKEND_IP:/opt/noflame/
scp Backend/wildfire_detection_model.h5 opc@BACKEND_IP:/opt/noflame/
scp Backend/unchecked_camera_image/image.jpeg opc@BACKEND_IP:/opt/noflame/unchecked_camera_image/

ssh opc@BACKEND_IP 'sudo systemctl start noflame'
```

### Step 6: Configure Frontend

Create `Frontend/vite-project/.env`:
```bash
VITE_API_URL=http://BACKEND_IP:5001
```

Run locally:
```bash
cd Frontend/vite-project
npm install
npm run dev    # Opens at http://localhost:5173
```

Or build and deploy to OCI Object Storage:
```bash
npm run build
oci os object bulk-upload \
  --bucket-name $(cd ../../infra && terraform output -raw frontend_bucket_name) \
  --src-dir dist --overwrite
```

### Step 7: Test

```bash
# Backend health check
curl http://BACKEND_IP:5001/fireAlarm
# Returns: false

# Weather data (San Francisco)
curl "http://BACKEND_IP:5001/getCurrentForecastFromLatLon?lat=37.7749&lon=-122.4194"
# Returns: JSON with temperature, humidity, wind data
```

Open the frontend in your browser and **allow location access** when prompted.

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/fireAlarm` | GET | Fire alarm status (true/false) |
| `/getCurrentForecastFromLatLon?lat=X&lon=X` | GET | Current weather for location |
| `/getFullForecastFromLatLon?lat=X&lon=X` | GET | Full hourly forecast |
| `/getFireRisk?lat=X&lon=X` | GET | Fire risk score (0-100) |
| `/upload_image` | POST | Upload camera image for ML analysis |

### Code Changes Made

**Frontend API URL** — Changed from hardcoded IP to environment-based config:
- Created `Frontend/vite-project/src/config/api.js` — reads `VITE_API_URL` from `.env`, falls back to `http://localhost:5001`
- Updated `Frontend/vite-project/src/Api.jsx` — imports `BASE_URL` from config instead of hardcoding
- Created `Frontend/vite-project/.env.example` — template for environment variables

**Infrastructure** — All Terraform files in `infra/` rewritten from AWS to Oracle Cloud:
- `providers.tf` — OCI provider authentication
- `main.tf` — VCN, subnet, security list, compute instance, object storage bucket
- `variables.tf` — OCI-specific variables (tenancy, user, fingerprint, etc.)
- `versions.tf` — `oracle/oci ~> 5.0` provider
- `outputs.tf` — Backend IP/URL, frontend URL, deployment commands
- `user_data.sh` — Oracle Linux 8 bootstrap (Python 3.11, TensorFlow, Gunicorn, 2GB swap)

**Instance shape change** — Ampere A1 Flex had no capacity in us-sanjose-1, switched to `VM.Standard.E2.1.Micro` (AMD). Added dynamic `shape_config` in `main.tf` so it works with both Flex and fixed shapes.

**Swap space** — Added 2GB swap creation to `user_data.sh` to prevent out-of-memory errors when installing TensorFlow on the 1GB Micro instance.

### Terraform File Structure

```
infra/
├── main.tf                  # VCN, compute, object storage resources
├── variables.tf             # Input variables (OCI auth, project config)
├── outputs.tf               # Deployment URLs and next-step commands
├── providers.tf             # OCI provider config
├── versions.tf              # Terraform >= 1.0.0, oracle/oci ~> 5.0
├── user_data.sh             # Instance bootstrap script
├── terraform.tfvars.example # Template (copy to terraform.tfvars)
├── terraform.tfvars         # Your values (gitignored)
└── .gitignore               # Ignores tfvars, tfstate, .terraform/
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "Out of host capacity" for A1 shape | Switch to `VM.Standard.E2.1.Micro` in terraform.tfvars |
| Instance OOM during pip install | Swap should be created by user_data.sh. Verify: `ssh opc@IP 'free -h'` |
| SSH connection refused | Wait 1-2 min after instance launch for SSH to start |
| user_data.sh failed at firewall-cmd | Run firewall commands manually via SSH (see `infra/README.md`) |
| Frontend shows "Unable to fetch" | Allow browser location permission, check backend is running |
| Google Maps "Oops! Something went wrong" | Configure API key referrer restrictions in Google Cloud Console |
| Backend 500 errors | Check logs: `ssh opc@IP 'sudo journalctl -u noflame -n 50'` |

### Teardown

```bash
cd infra
terraform destroy   # Type 'yes' — removes all OCI resources
```

### Cost: $0/month (Always Free forever)


## Inspiration

The inspiration behind NoFlame was sparked by the Palisade Fires in Los Angeles. When my mom sent pictures of the beautiful mountains, I, and many others, always found solace in absolute flames, and I was heartburned. We thought to ourselves, it's 2025, there should be no reason for a flame that has burned:

- 14,117 acres with only 15% contained
- 39,428 structures threatened
- 972 structures destroyed; 98 structures damaged
- 5 civilian fatalities; and 5 firefighter injuries for just Eaton Canyon alone is ridiculous.

## Purpose

NoFlame is an innovative fire detection and prevention system that uses advanced technology to protect lives and property. Here’s how it works and how it’s designed to scale:

- **Real-Time Fire Detection**:  
  NoFlame leverages machine learning to analyze camera feeds for flames while incorporating weather API data such as geolocation, humidity, wind speed, wind direction, and a Fire Weather Index (FWI). This comprehensive approach ensures rapid and accurate fire detection, enabling first responders and users to act swiftly before the fire spreads.  

- **IoT-Powered Alerts for Immediate Response**:  
  When a fire is detected, NoFlame sends real-time alerts to connected devices, notifying homeowners, businesses, and emergency responders. These alerts are designed to provide crucial information, enabling swift decision-making.  

- **Environmental Risk Analysis**:  
  By integrating data from weather APIs, NoFlame calculates fire risk indices using temperature, humidity, and wind speed. This proactive approach identifies potential hazards before fires even start.  

- **Seamless First Responder Integration**:  
  Using IoT and a centralized server, NoFlame can scale to provide critical fire data directly to first responders. Equipped with accurate, real-time updates on fire locations and conditions, emergency teams can act faster and more effectively to contain fires before they spiral out of control.  

- User-Friendly Monitoring:  
  A sleek web application allows users to monitor fire risks, view live camera feeds, and receive alerts tailored to their location. On-site alarms, like buzzers, ensure safety measures are deployed immediately.  

- Scalable Community Protection:  
  Beyond individual users, NoFlame is designed to scale for community-wide deployment. With its server-powered architecture, entire neighborhoods or rural areas can be monitored, creating a network of interconnected safety systems that work together to prevent large-scale disasters.  

- Actionable Insights and Education:  
  NoFlame educates users and responders with fire risk trends, historical data, and safety tips. This empowers communities to adopt preventive measures and fosters collaboration in fire safety.  

By combining IoT, machine learning, and centralized server technology, NoFlame transforms fire detection into a proactive and scalable solution. It empowers individuals and equips first responders with the tools they need to mitigate fires swiftly and effectively, ensuring tragedies like the Palisade Fires become a thing of the past.  


## Build Process

1. Brainstorming: Our group initially ruled out the environment Track, deeming it too hard. However, when one of our moms sent an image of our backyard in hellish flames, we knew we had to create a project based on this.

2. Organization: Once the concrete idea was set, we created a Venn diagram consisting of 4 main components: Frontend (UI/UX), Backend (Flask, Personal Server, Weather API Scraping, Etc), Machine Learning Model and Hardware (Tensorflow, sci-kit-learn, Arduino, Breadboard, ESP32), and finally the MVP.

3. Execution: As a group, we decided to play to our individual strengths to create the best cohesive product we could. Given that Frontend can be more challenging than the others, we assigned two people on the Frontend, one expert backend for backend, and one for the ML and Hardware aspect. For more in-depth details, please visit our booth.

4. Putting it all together: Once all 3-4 aspects were done, we simply merged the created individual branches and created our cohesive project, NoFlame

## Challenges

- Remembering how to use CNNs to train a classification model.
- Learning how to use an ESP32 and breadboard for the first time
- Learning the Arduino IDE code for electronics like the Buzzer and Button
- Learning how to create a Flask server and run it on an existing Linux Server that isn't physically here with us
- Web scraping data, especially those that had a paywall
- Learning how to use Vite and React
- Creating animations for Flames and using Geolocation for Real-Time Google maps update.

## Accomplishments

- Mastering CNNs:  
  We managed to recall and apply our knowledge of Convolutional Neural Networks to build an accurate fire classification model. This felt like reviving dormant skills and putting them to impactful use.

- Diving into New Hardware:  
  None of us had worked with an ESP32 or breadboard before, but now, we can confidently wire up components like a button and a buzzer and make them work in harmony.

- Arduino Expertise:  
  Writing Arduino IDE code was uncharted territory for some of us, but we pushed through to create working hardware that complemented our software seamlessly.

- Flask and Remote Linux Servers:  
  Setting up and running a Flask server on a Linux server that's physically hundreds of miles away was no small feat, but we made it happen and integrated it into the project smoothly.

- Web Scraping Obstacles:  
  Breaking through barriers like paywalls and limited access APIs, we scraped and processed the data we needed for weather and geolocation.

- UI/UX Innovations:  
  Using Vite and React for the frontend, we built a clean, functional interface, complete with animations and a real-time Google Maps fire visualization.

- Bringing It All Together:  
  Despite these challenges, we integrated all the components—frontend, backend, machine learning, and hardware—into one cohesive system that truly embodies our vision for NoFlame.

We didn’t just tackle the hard stuff; we turned it into a product we’re genuinely proud of.


## Next Up

- Community-Wide Deployment: We aim to expand NoFlame’s reach by integrating more IoT devices and creating a network that monitors entire neighborhoods and natural areas in real-time.  
- First Responder Collaboration: Partnering with fire departments to provide direct alerts and real-time data, empowering them to act faster and with more precision.  
- Improved Fire Risk Analytics: Enhancing our Fire Weather Index (FWI) calculations by incorporating more environmental factors and satellite data for even more accurate predictions.  
- Mobile App Integration: Building a mobile app to make NoFlame’s alerts, live feeds, and fire risk indices accessible to users wherever they are.  
- Machine Learning Optimization: Refining our CNN model with more diverse datasets to improve accuracy and reduce false positives in fire detection.  
- Hardware Iteration: Scaling down hardware requirements to make on-site alarms more compact, affordable, and easier to deploy across various environments.  
- Hardware Addition: Incorporating Infrared with the cameras to easily detect if a fire is present. For a more in-depth explanation, please come to our booth!

NoFlame isn’t just a project, it’s the beginning of a vision to turn reactive fire safety into proactive fire prevention, creating safer communities for everyone. Protection of Inaction.
