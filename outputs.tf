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
