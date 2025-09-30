variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the existing public subnet"
  type        = string
}

variable "aws_key_name" {
  description = "Name of the existing AWS key pair"
  type        = string
}

variable "ssh_private_key" {
  description = "Content of the SSH private key"
  type        = string
}
