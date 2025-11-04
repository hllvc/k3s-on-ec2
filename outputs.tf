output "kubeconfig" {
  value = replace(
    data.local_file.kubeconfig.content,
    "0.0.0.0",
    aws_instance.this.public_ip
  )
  sensitive = true
}

output "ssh_public_key" {
  description = "SSH public key for the generated key pair"
  value       = tls_private_key.this.public_key_openssh
}
