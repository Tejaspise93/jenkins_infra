# Fetch Default VPC
data "aws_vpc" "default" {
  default = true
}

module "jenkins_sg" {
  source   = "./modules/security_groups"
  sg_ports = var.jenkins_ports_to_allow
  vpc_id   = data.aws_vpc.default.id
  sg_name  = var.jenkins_sg_name
}
