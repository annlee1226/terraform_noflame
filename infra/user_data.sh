#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== NoFlame Backend Setup Started ==="

# Create 2GB swap (prevents OOM on 1GB instances)
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# Update system (Oracle Linux 8 uses dnf)
dnf update -y

# Install Python 3.11 and dependencies
dnf install -y python3.11 python3.11-pip python3.11-devel
dnf install -y gcc gcc-c++ make git

# Install OpenCV dependencies
dnf install -y mesa-libGL

# Open firewall ports (Oracle Linux uses firewalld)
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=5001/tcp
firewall-cmd --reload

# Create app directory
mkdir -p /opt/noflame
mkdir -p /opt/noflame/unchecked_camera_image

# Create virtual environment
python3.11 -m venv /opt/noflame/venv

# Install Python packages (use tflite-runtime instead of full tensorflow to save RAM)
/opt/noflame/venv/bin/pip install --upgrade pip
/opt/noflame/venv/bin/pip install --no-cache-dir \
    flask \
    flask-cors \
    tensorflow \
    pillow \
    numpy \
    requests \
    timezonefinder \
    gunicorn

# Create systemd service (runs on port 5001)
cat > /etc/systemd/system/noflame.service << 'EOF'
[Unit]
Description=NoFlame Flask Backend
After=network.target

[Service]
User=opc
Group=opc
WorkingDirectory=/opt/noflame
Environment="PATH=/opt/noflame/venv/bin"
ExecStart=/opt/noflame/venv/bin/gunicorn \
    --bind 0.0.0.0:5001 \
    --workers 2 \
    --timeout 120 \
    app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Set ownership (OCI uses 'opc' user instead of 'ec2-user')
chown -R opc:opc /opt/noflame

# Enable service (will start after code is deployed)
systemctl daemon-reload
systemctl enable noflame

echo "=== NoFlame Backend Setup Complete ==="
echo "Deploy your Backend code to /opt/noflame/ then run:"
echo "  sudo systemctl start noflame"
