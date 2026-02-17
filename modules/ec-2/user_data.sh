#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -ux

echo "== Setup started: $(date) =="

# Wait for the EBS volume to be available
echo ">> Waiting for device /dev/xvdf..."
while [ ! -b /dev/xvdf ]; do
  sleep 5
done
echo ">> Device ready!"


# Format the volume (only if it has no filesystem yet)
if ! blkid /dev/xvdf &>/dev/null; then
  echo ">> Formatting /dev/xvdf as ext4..."
  mkfs -t ext4 /dev/xvdf
else
  echo ">> Filesystem already exists, skipping format"
fi


# Create jenkins user with home dir at /var/lib/jenkins
echo ">> Creating jenkins user..."
useradd \
  --system \
  --home-dir /var/lib/jenkins \
  --shell /bin/bash \
  jenkins


# Mount the volume on /var/lib/jenkins
echo ">> Mounting volume..."
mount /dev/xvdf /var/lib/jenkins

# Set correct ownership
chown -R jenkins:jenkins /var/lib/jenkins

# Persist the mount so it survives reboots
UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$UUID  /var/lib/jenkins  ext4  defaults,nofail  0  2" >> /etc/fstab
echo ">> Mounted and persisted in fstab"



# Install Java (Jenkins requires it)
echo ">> Installing Java 17..."
dnf install -y java-21-amazon-corretto-headless

# Add Jenkins repo
echo ">> Adding Jenkins repo..."
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo || \
  { echo "ERROR: Failed to download Jenkins repo"; exit 1; }

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key || \
  { echo "ERROR: Failed to import Jenkins key"; exit 1; }

# Install Jenkins
echo ">> Installing Jenkins..."
dnf install -y jenkins

# Start Jenkins
echo ">> Starting Jenkins..."
systemctl enable jenkins
systemctl start jenkins

echo "== Setup complete: $(date) =="