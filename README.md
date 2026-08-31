# Jenkins Practice Server on AWS — Terraform

A Terraform project that spins up a fresh Jenkins server on AWS for practice. Designed to be created in the morning and destroyed in the evening to stay within AWS free tier.

Jenkins data lives on a dedicated 10GB EBS volume mounted at `/var/lib/jenkins` — keeping it separate from the OS disk.

---

## What This Creates

| Resource | Details |
|----------|---------|
| `aws_key_pair` | Registers your public SSH key in AWS |
| `aws_security_group` | Opens port 22 (SSH) and 8080 (Jenkins UI) |
| `aws_instance` | Amazon Linux 2023, t3.micro (free tier eligible) |
| `aws_ebs_volume` | 10GB gp3 dedicated volume for Jenkins home |
| `aws_volume_attachment` | Attaches the volume to the instance at `/dev/xvdf` |

At the end of `terraform apply` the Jenkins initial admin password is automatically printed to your terminal.

---

## Prerequisites

Before you start make sure you have:

- An AWS account with CLI configured (`aws configure`)
- Terraform >= 1.5.0 ([install guide](https://developer.hashicorp.com/terraform/install))
- Git Bash or any terminal with SSH support

---

## Getting Started

### Step 1 — Clone the repo

```bash
git clone <repo-url>
cd <repo-folder>
```

### Step 2 — Generate an SSH key pair

This key is how you and Terraform SSH into the server.

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins_key -N ""
mv ~/.ssh/jenkins_key ~/.ssh/jenkins_key.pem
chmod 400 ~/.ssh/jenkins_key.pem
```

Two files are created:
- `jenkins_key.pem` — your private key, stays on your machine only
- `jenkins_key.pub` — public key, uploaded to AWS by Terraform

### Step 3 — Create your `terraform.tfvars`

This file is not included in the repo (it contains paths specific to your machine). Create it in the project root:

```hcl
aws_region       = "us-east-1"
instance_type    = "t3.micro"
public_key_path  = "~/.ssh/jenkins_key.pub"
private_key_path = "~/.ssh/jenkins_key.pem"
```

> **Note:** On Windows use forward slashes `/` not backslashes `\` in paths.
> Use `C:/Users/YOUR_USERNAME/.ssh/jenkins_key.pem` if `~` does not resolve correctly.

### Step 4 — Initialise Terraform

```bash
terraform init
```

### Step 5 — Apply

```bash
terraform apply
```

Type `yes` when prompted. This takes around 8-10 minutes. At the end you will see:

```
Outputs:

jenkins_url = "http://1.2.3.4:8080"
public_ip   = "1.2.3.4"
ssh_command = "ssh -i ~/.ssh/jenkins_key.pem ec2-user@1.2.3.4"

================================================
        JENKINS INITIAL ADMIN PASSWORD
================================================
YOUR_PASSWORD_HERE
================================================

# use to switch to jenkins user if you want to ssh
sudo -u jenkins -s /bin/bash

```

Open `jenkins_url` in your browser and use the printed password to complete Jenkins setup.

---

## Project Structure

```
your-project/
├── main.tf                   # Provider, key pair, data sources, module calls
├── variables.tf              # Root input variables
├── outputs.tf                # Jenkins URL, SSH command, public IP
├── terraform.tfvars          # Your values — create this yourself (not in repo)
└── modules/
    ├── security-group/       # Creates the firewall rules
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2-instance/         # Creates the Jenkins server
        ├── main.tf           # EC2, EBS volume, attachment, remote-exec
        ├── variables.tf      # Module input variables
        ├── outputs.tf        # IP, URL, SSH command
        └── user_data.sh      # Bootstrap script — runs on first boot
```

---

## Requirements

| Tool | Minimum Version |
|------|----------------|
| Terraform | >= 1.5.0 |
| AWS Provider | ~> 5.0 |
| AWS CLI | any recent version |