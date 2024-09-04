#!/bin/bash

# Check for required argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <private-instance-ip>"
  exit 1
fi

# Define variables
PRIVATE_IP=$1
PUBLIC_KEY_PATH="/home/ubuntu/.ssh/newjohn-VMPS.pem"
NEW_KEY_PATH=~/.ssh/id_rsa_new

# Ensure correct permissions on the private key file
chmod 600 $PUBLIC_KEY_PATH

# Generate a new key pair with a passphrase
ssh-keygen -t rsa -b 4096 -f $NEW_KEY_PATH -C "New SSH key for private instance"

# Enable agent forwarding for the connection
SSH_OPTS="-o ForwardAgent=yes"

# Copy the new public key to the authorized_keys file on the private instance
scp -i $PUBLIC_KEY_PATH $SSH_OPTS /tmp/ssh_config ubuntu@$PRIVATE_IP:/tmp/ssh_config
scp -i $PUBLIC_KEY_PATH $SSH_OPTS $PUBLIC_KEY_PATH ubuntu@$PRIVATE_IP:~/.ssh/authorized_keys

# Test the new key (comment out if not desired)
# ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP

# Remove  temporary configuration
rm /tmp/ssh_config

# Update authorized_keys on the private instance, replacing the old file
ssh -i $NEW_KEY_PATH $SSH_OPTS ubuntu@$PRIVATE_IP "mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys.old; cat $NEW_KEY_PATH >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

# (Optional) Remove the old authorized_keys file on the private instance
ssh -i $NEW_KEY_PATH $SSH_OPTS ubuntu@$PRIVATE_IP "rm -f ~/.ssh/authorized_keys.old"

# Print instructions for connecting with the new key
echo "Connection to the private instance is now possible with the new key:"
echo "ssh -i $NEW_KEY_PATH ubuntu@$PRIVATE_IP"

# (Optional) Disable password login (if desired)
# ssh -i $NEW_KEY_PATH $SSH_OPTS ubuntu@$PRIVATE_IP "sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config; sudo systemctl restart ssh"

echo "SSH key rotation completed."