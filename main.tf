# Fetch Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

# Fetch available instance types in the region to ensure the specified instance type is valid 
# problem faced in us-east-1e availability zone no t3.micro
data "aws_ec2_instance_type_offerings" "available" {
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  location_type = "availability-zone"
}

# Fetch subnets in the default VPC
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

# -------------------------------------------------
# security group for jenkins server
#--------------------------------------------------
module "jenkins_sg" {
  source   = "./modules/security_groups"
  sg_ports = var.jenkins_ports_to_allow
  vpc_id   = data.aws_vpc.default.id
  sg_name  = var.jenkins_sg_name
}

# -------------------------------------------------
# key pair for jenkins server
#--------------------------------------------------
resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-practice-key"
  public_key = file(var.public_key_path)
}

# -------------------------------------------------
# EC2 instance for jenkins server
#--------------------------------------------------
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