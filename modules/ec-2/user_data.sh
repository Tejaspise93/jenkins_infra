#!/bin/bash
exec > /var/log/user-data.log 2>&1

sudo yum install -y java-21*

# ── Wait for EBS volume ──────────────────────────────
echo ">> Waiting for device /dev/xvdf..."
while [ ! -b /dev/xvdf ]; do
  sleep 5
done
echo ">> Device ready!"

# ── Format volume ────────────────────────────────────
if ! blkid /dev/xvdf &>/dev/null; then
  echo ">> Formatting /dev/xvdf as ext4..."
  mkfs -t ext4 /dev/xvdf
else
  echo ">> Filesystem already exists, skipping format"
fi

# ── Create jenkins user ──────────────────────────────
useradd \
  --system \
  --home-dir /var/lib/jenkins \
  --shell /bin/bash \
  jenkins

# ── Mount volume on jenkins home ─────────────────────
mkdir -p /var/lib/jenkins
mount /dev/xvdf /var/lib/jenkins
chown -R jenkins:jenkins /var/lib/jenkins

# Persist mount across reboots
UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$UUID  /var/lib/jenkins  ext4  defaults,nofail  0  2" >> /etc/fstab

# ── Install Jenkins ──────────────────────────────────
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

echo "== Setup complete: $(date) =="