data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id

  user_data = file("${path.module}/user_data.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = var.instance_name
  }
}


resource "aws_ebs_volume" "jenkins_home_volume" {
    availability_zone = aws_instance.jenkins_instance.availability_zone
    size = 10
    type = "gp3"

    tags = {
      Name = "${var.instance_name}-jenkins_home_volume"
    }
}

resource "aws_volume_attachment" "jenkins_home_attachment" {
    device_name = "/dev/xvdf"
    volume_id = aws_ebs_volume.jenkins_home_volume.id
    instance_id = aws_instance.jenkins_instance.id
}


resource "null_resource" "get_jenkins_password" {

  triggers = {
    instance_id = aws_instance.jenkins_instance.id
  }

  connection {
    type        = "ssh"
    host        = aws_instance.jenkins_instance.public_ip
    user        = var.ssh_user
    private_key = file(var.private_key_path)
    timeout     = "8m"
  }

  provisioner "remote-exec" {
  inline = [
    "echo '>> Waiting for user_data to complete...'",
    "until [ -f /var/log/user-data.log ] && grep -q 'Setup complete' /var/log/user-data.log; do sleep 10; echo 'waiting for setup...'; done",
    "echo '>> Waiting for Jenkins password file...'",
    "until sudo test -f /var/lib/jenkins/secrets/initialAdminPassword; do sleep 10; echo 'waiting for Jenkins...'; done",
    "echo '================================================'",
    "echo '        JENKINS INITIAL ADMIN PASSWORD'",
    "echo '================================================'",
    "sudo cat /var/lib/jenkins/secrets/initialAdminPassword",
    "echo '================================================'",
  ]
  }

  depends_on = [aws_volume_attachment.jenkins_home_attachment]
}