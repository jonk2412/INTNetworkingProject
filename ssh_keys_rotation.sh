#!/bin/bash

# Check for required argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <private-instance-ip>"
  exit 1
fi

# Define variables
PRIVATE_IP=$1
PUBLIC_KEY_PATH=~/.ssh/id_rsa.pub
NEW_KEY_PATH=~/.ssh/id_rsa_new

# Generate a new key pair with a passphrase
ssh-keygen -t rsa -b 4096 -f $NEW_KEY_PATH -C "New SSH key for private instance"

# Ensure strict host key checking is disabled for the initial connection
echo "StrictHostKeyChecking=no" > /tmp/ssh_config

# Copy the new public key to the authorized_keys file on the private instance
scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no /tmp/ssh_config ubuntu@$PRIVATE_IP:/tmp/ssh_config
scp -i ~/.ssh/id_rsa $PUBLIC_KEY_PATH ubuntu@$PRIVATE_IP:~/.ssh/authorized_keys

# Test the new key (comment out if not desired)
# ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP

# Remove temporary configuration
rm /tmp/ssh_config

# Update authorized_keys on the private instance (remove old key if possible)
ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP "cat $NEW_KEY_PATH >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

# Print instructions for connecting with the new key
echo "Connection to the private instance is now possible with the new key:"
echo "ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP"

# (Optional) Disable password login (if desired)
# ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP "sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config; sudo systemctl restart ssh"

echo "SSH key rotation completed."