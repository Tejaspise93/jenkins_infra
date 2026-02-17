variable "instance_type" {
  description = "instance type for the ec2 instance tobe created"
  type        = string
}

variable "instance_name" {
  description = "name of the ec2 instance"
  type        = string
}

variable "key_name" {
  description = "key name"
  type        = string
}

variable "ssh_user" {
  description = "SSH user for the AMI"
  type        = string
  default     = "ec2-user"
}

variable "private_key_path" {
  description = "Local path to your .pem file for the remote provisioner"
  type        = string
}
variable "security_group_id" {
  description = "security group to be used"
  type = string
}

variable "subnet_id" {
  description = "subnet id to be used"
  type        = string
}
