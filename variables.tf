variable "aws_region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "rdp_user" {
  description = "Linux/RDP username"
}

variable "rdp_password" {
  description = "Linux/RDP password"
  sensitive   = true
}
