# Let's generate random name for different resources to be uniqe
resource "random_string" "this" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# Security Group for K3s
resource "aws_security_group" "this" {
  name        = random_string.this.result
  description = "Security group for K3s cluster"
  vpc_id      = var.vpc_id

  # Kubernetes API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data source to find the latest Ubuntu AMI
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  owners = ["099720109477"] # Canonical (Ubuntu)
}

# EC2 Instance with K3s
resource "aws_instance" "this" {
  ami           = data.aws_ami.this.id
  instance_type = "t3.medium"

  key_name = var.aws_key_name

  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]

  # Ensure the instance gets a public IP
  associate_public_ip_address = true

  user_data_base64 = base64encode(file("${path.module}/user_data.sh"))

  provisioner "remote-exec" {
    when = create

    connection {
      host        = self.public_ip
      user        = "ubuntu"
      private_key = var.ssh_private_key
    }

    inline = [<<-EOT
      until [ -f /etc/rancher/k3s/k3s.yaml ]; do
        echo "The '/etc/rancher/k3s/k3s.yaml' is not available.. Retrying in 10 seconds.."
        sleep 10
      done
      echo "The 'k3s.yaml' has been created. K3s is ready."
      EOT
    ]
  }

  provisioner "local-exec" {
    when = create

    quiet   = true
    command = <<-EOT
      TEMP_KEY="$(mktemp)"
      echo "${var.ssh_private_key}" > "$TEMP_KEY"
      ssh -o StrictHostKeyChecking=no \
        -i "$TEMP_KEY" \
        ubuntu@${aws_instance.this.public_ip} \
        "sudo cat /etc/rancher/k3s/k3s.yaml" > .kubeconfig
      rm -f "$TEMP_KEY"
    EOT
  }

  provisioner "local-exec" {
    when = destroy

    quiet   = true
    command = <<-EOT
      [ -f .kubeconfig ] && rm .kubeconfig
    EOT
  }
}
