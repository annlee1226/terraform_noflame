# =============================================================================
# Outputs - Important URLs and values after deployment
# =============================================================================

output "frontend_bucket_name" {
  description = "Object Storage bucket name for frontend"
  value       = oci_objectstorage_bucket.frontend.name
}

output "frontend_namespace" {
  description = "Object Storage namespace"
  value       = data.oci_objectstorage_namespace.ns.namespace
}

output "frontend_url" {
  description = "URL to access frontend files (direct object access)"
  value       = "https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.ns.namespace}/b/${oci_objectstorage_bucket.frontend.name}/o/index.html"
}

output "backend_public_ip" {
  description = "Public IP of the backend compute instance"
  value       = oci_core_instance.backend.public_ip
}

output "backend_url" {
  description = "URL of the backend API"
  value       = "http://${oci_core_instance.backend.public_ip}:5001"
}

# =============================================================================
# Deployment Commands - Copy/paste these after terraform apply
# =============================================================================

output "next_steps" {
  description = "Commands to deploy your application"
  value       = <<-EOT

    ============================================================
    DEPLOYMENT STEPS
    ============================================================

    1. UPDATE FRONTEND CONFIG:
       Create Frontend/vite-project/.env with:
       VITE_API_URL=http://${oci_core_instance.backend.public_ip}:5001

    2. BUILD FRONTEND:
       cd Frontend/vite-project
       npm install
       npm run build

    3. DEPLOY FRONTEND TO OCI OBJECT STORAGE:
       # Upload files to the bucket:
       oci os object bulk-upload \
         --bucket-name ${oci_objectstorage_bucket.frontend.name} \
         --src-dir Frontend/vite-project/dist \
         --overwrite

    4. DEPLOY BACKEND TO COMPUTE:
       scp -r Backend/* opc@${oci_core_instance.backend.public_ip}:/opt/noflame/

    5. START BACKEND:
       ssh opc@${oci_core_instance.backend.public_ip}
       sudo systemctl start noflame
       sudo systemctl status noflame

    6. TEST:
       Backend:  http://${oci_core_instance.backend.public_ip}:5001/fireAlarm
       Frontend: https://objectstorage.${var.region}.oraclecloud.com/n/${data.oci_objectstorage_namespace.ns.namespace}/b/${oci_objectstorage_bucket.frontend.name}/o/index.html

    ============================================================

  EOT
}
