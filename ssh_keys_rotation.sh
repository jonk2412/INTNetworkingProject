#!/bin/bash

# Private instance IP address (passed as argument)
private_ip="$1"

# Temporary directory for key generation
tmp_dir=$(mktemp -d)

# Generate a new SSH key pair
ssh-keygen -b 4096 -t rsa -f "$tmp_dir/id_rsa" -N "" &>/dev/null

# Copy the new public key to the authorized_keys file on the private instance
ssh -i ~/.ssh/key.pem ubuntu@"$private_ip" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
scp -i ~/.ssh/key.pem "$tmp_dir/id_rsa.pub" ubuntu@"$private_ip":~/.ssh/authorized_keys

# Set permissions on authorized_keys
ssh -i ~/.ssh/key.pem ubuntu@"$private_ip" "chmod 600 ~/.ssh/authorized_keys"

# (Optional) Disable the old key in authorized_keys (recommended after a grace period)
# Uncomment the following line to implement this functionality:
# ssh -i ~/.ssh/key.pem ubuntu@"$private_ip" "sed -i '/<old_key_fingerprint>/d' ~/.ssh/authorized_keys"

# Restart SSH service on the private instance
ssh -i ~/.ssh/key.pem ubuntu@"$private_ip" "sudo service ssh restart"

# Clean up temporary directory
rm -rf "$tmp_dir"

echo "SSH key rotation completed on $private_ip. Use the newly generated key pair for future connections."
