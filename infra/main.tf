# =============================================================================
# NoFlame Infrastructure - Oracle Cloud Always Free Tier
# =============================================================================
# Resources created:
#   - Object Storage bucket for frontend static files (Always Free: 20GB)
#   - Ampere A1 compute instance for backend (Always Free: 4 OCPUs, 24GB RAM)
#   - VCN with public subnet
#   - Security list for HTTP/HTTPS/Flask/SSH access
#
# Always Free limits:
#   - 2 AMD Compute VMs (1/8 OCPU, 1GB RAM each) OR
#   - Up to 4 Ampere A1 OCPUs and 24GB RAM (can be 1 VM or multiple)
#   - 200GB block storage
#   - 10GB object storage (standard), 20GB (infrequent access)
#   - 10TB outbound data transfer per month
# =============================================================================

# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
}

# =============================================================================
# DATA SOURCES
# =============================================================================

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get Oracle Linux image for Ampere A1
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# =============================================================================
# NETWORKING - VCN, Subnet, Internet Gateway, Security List
# =============================================================================

# Virtual Cloud Network
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.project_name}-vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  dns_label      = var.project_name
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-igw"
  enabled        = true
}

# Route Table
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# Security List
resource "oci_core_security_list" "backend" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-backend-sl"

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # HTTP (80)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTP"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS (443)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "HTTPS"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Flask API (5001)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    stateless   = false
    description = "Flask API"

    tcp_options {
      min = 5001
      max = 5001
    }
  }

  # SSH (22) - only if allowed_ssh_cidrs is provided
  dynamic "ingress_security_rules" {
    for_each = var.allowed_ssh_cidrs
    content {
      protocol    = "6"
      source      = ingress_security_rules.value
      stateless   = false
      description = "SSH from ${ingress_security_rules.value}"

      tcp_options {
        min = 22
        max = 22
      }
    }
  }
}

# Public Subnet
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  display_name               = "${var.project_name}-public-subnet"
  cidr_block                 = "10.0.1.0/24"
  dns_label                  = "public"
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.backend.id]
  prohibit_public_ip_on_vnic = false
}

# =============================================================================
# OBJECT STORAGE - Frontend Static Website
# =============================================================================

# Object Storage Namespace (required for bucket operations)
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

# Object Storage Bucket
resource "oci_objectstorage_bucket" "frontend" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = local.bucket_name
  access_type    = "ObjectRead" # Public read access for static website

  freeform_tags = {
    Project = var.project_name
  }
}

# =============================================================================
# COMPUTE - Backend API Server (Ampere A1 - Always Free)
# =============================================================================

resource "oci_core_instance" "backend" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${var.project_name}-backend"
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = length(regexall("Flex", var.instance_shape)) > 0 ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux.images[0].id
    boot_volume_size_in_gbs = 50 # 50GB boot volume (Always Free: up to 200GB total)
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "${var.project_name}-backend-vnic"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/user_data.sh"))
  }

  freeform_tags = {
    Project = var.project_name
  }
}
