variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "m7i-flex.large"
}

variable "allowed_cidr" {
  description = "CIDR block allowed to access RDP"
}

variable "vm_name" {
  description = "Name of the EC2 VM"
}

variable "rdp_user" {
  description = "Linux/RDP username"
}

variable "rdp_password" {
  description = "Linux/RDP password"
  sensitive   = true
}
