output "instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_instance.id
}

output "public_ip" {
  description = "Public IP of the Jenkins instance"
  value       = aws_instance.jenkins_instance.public_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${aws_instance.jenkins_instance.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.private_key_path} ${var.ssh_user}@${aws_instance.jenkins_instance.public_ip}"
}