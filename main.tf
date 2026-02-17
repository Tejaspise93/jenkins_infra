# Fetch Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  location_type = "availability-zone"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "availabilityZone"
    values = data.aws_ec2_instance_type_offerings.available.locations
  }
}

module "jenkins_sg" {
  source   = "./modules/security_groups"
  sg_ports = var.jenkins_ports_to_allow
  vpc_id   = data.aws_vpc.default.id
  sg_name  = var.jenkins_sg_name
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-practice-key"
  public_key = file(var.public_key_path)
}

module "jenkins_server" {
  source = "./modules/ec-2"

  instance_type     = var.instance_type
  instance_name     = "jenkins-practice"
  key_name          = aws_key_pair.jenkins.key_name
  private_key_path  = var.private_key_path
  ssh_user          = "ec2-user"
  security_group_id = module.jenkins_sg.jenkins_sg_id
  subnet_id         = tolist(data.aws_subnets.default.ids)[0]
}