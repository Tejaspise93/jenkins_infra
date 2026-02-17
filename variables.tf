variable "aws_region" {
  description = "region to be used"
  default     = "us-east-1"
}

variable "jenkins_ports_to_allow" {
  description = "ports to be allowed in the security group"
  default     = [8080, 22]
}

variable "jenkins_sg_name" {
  description = "name of security group"
  default     = "jenkins-sg"
}

variable "public_key_path" {
  description = "Path to your .pub public key file"
  type        = string
}

variable "private_key_path" {
  description = "Path to your .pem private key file"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}