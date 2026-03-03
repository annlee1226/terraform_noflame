# =============================================================================
# OCI Authentication
# =============================================================================

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key file"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., us-ashburn-1, us-phoenix-1)"
  type        = string
  default     = "us-ashburn-1"
}

# =============================================================================
# Project Configuration
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "noflame"
}

variable "ssh_public_key" {
  description = "SSH public key for compute instance access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH (e.g., your IP). Leave empty to disable SSH."
  type        = list(string)
  default     = []
}

# =============================================================================
# Compute Configuration (Always Free: Ampere A1 with 4 OCPUs, 24GB RAM total)
# =============================================================================

variable "instance_shape" {
  description = "Compute instance shape. VM.Standard.A1.Flex is Always Free eligible."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance (Always Free: up to 4 total)"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Memory in GB for the instance (Always Free: up to 24GB total)"
  type        = number
  default     = 6
}
