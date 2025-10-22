output "kubeconfig" {
  value = replace(
    fileexists("${path.module}/.kubeconfig")
    ? file("${path.module}/.kubeconfig")
    : "",
    "0.0.0.0",
    aws_instance.this.public_ip
  )
  sensitive = true
}

output "ssh_public_key" {
  description = "SSH public key for the generated key pair"
  value       = tls_private_key.this.public_key_openssh
}
