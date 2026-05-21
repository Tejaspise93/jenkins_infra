#!/bin/bash
exec > /var/log/user-data.log 2>&1

# Increase /tmp size to 2GB
# This is necessary for Jenkins to run properly, as it uses /tmp for various operations
# and it fails to start if /tmp is too small. 
# The default size of /tmp on Amazon Linux 2 is 512MB, which is not sufficient for Jenkins.
mount -o remount,size=2G /tmp

# Install Java
sudo yum install -y java-21*

# Install supporting tools
sudo yum install -y git

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install yq
YQ_VERSION="v4.44.3"
sudo wget -qO /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
sudo chmod +x /usr/local/bin/yq

# Wait for EBS volume
echo ">> Waiting for device /dev/xvdf..."
while [ ! -b /dev/xvdf ]; do
  sleep 5
done
echo ">> Device ready!"

# Format volume
if ! blkid /dev/xvdf &>/dev/null; then
  echo ">> Formatting /dev/xvdf as ext4..."
  mkfs -t ext4 /dev/xvdf
else
  echo ">> Filesystem already exists, skipping format"
fi

# Mount volume on jenkins home
mkdir -p /var/lib/jenkins
mount /dev/xvdf /var/lib/jenkins

# Persist mount across reboots
UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$UUID  /var/lib/jenkins  ext4  defaults,nofail  0  2" >> /etc/fstab

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo yum install jenkins -y 

# chaing ownership and adding jenkins user to docker group so jenkins can run docker command
chown -R jenkins:jenkins /var/lib/jenkins
sudo usermod -aG docker jenkins

sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "== Setup complete: $(date) =="