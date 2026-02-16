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
  default = "jenkins-sg"
  
}