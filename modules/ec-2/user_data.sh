#!/bin/bash
exec > /var/log/user-data.log 2>&1

# Increase /tmp size to 2GB
# This is necessary for Jenkins to run properly, as it uses /tmp for various operations
# and it fails to start if /tmp is too small. 
# The default size of /tmp on Amazon Linux 2 is 512MB, which is not sufficient for Jenkins.
mount -o remount,size=2G /tmp

# Install Java
yum install -y java-21*

# Install supporting tools
yum install -y git
yum install -y maven  

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Install yq
YQ_VERSION="v4.44.3"
wget -qO /usr/local/bin/yq \
  "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
chmod +x /usr/local/bin/yq

# Install Jenkins package FIRST (so system paths and user account are safely initialized)
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

yum install jenkins -y 


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

# Mount volume on jenkins home directory (overrides package skeleton)
mkdir -p /var/lib/jenkins
mount /dev/xvdf /var/lib/jenkins

# Persist mount across reboots
UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$UUID  /var/lib/jenkins  ext4  defaults,nofail  0  2" >> /etc/fstab

# Change ownership and adding jenkins user to docker group so jenkins can run docker command
chown -R jenkins:jenkins /var/lib/jenkins
usermod -aG docker jenkins

# Refresh services and run Jenkins
systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

echo "== Setup complete: $(date) =="
