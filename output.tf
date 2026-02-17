output "jenkins_url" {
  description = "Open this in your browser to access Jenkins"
  value       = module.jenkins_server.jenkins_url
}

output "ssh_command" {
  description = "Run this to SSH into the server"
  value       = module.jenkins_server.ssh_command
}

output "public_ip" {
  description = "Public IP of the Jenkins server"
  value       = module.jenkins_server.public_ip
}