#!/bin/bash

# Check if KEY_PATH environment variable is set
if [[ -z "${KEY_PATH}" ]]; then
  echo "Error: KEY_PATH environment variable is not set."
  exit 5
fi

# Check for required arguments (at least 2)
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <bastion_ip> <target_host>"
  echo "OR"
  echo "Usage: $0 <bastion_ip> <target_host> <command_to_run>"
  exit 1
fi

# Extrac t argum ents
bastion_ip="$1"
target_host="$2"
command_to_run="${3:-}"  # Optional command (default empty)

# Connect to the bastion host using SSH
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@"$bastion_ip" << EOF
  # Connect to the target host using SSH again
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@"$target_host" $command_to_run
EOF

# Exit script with the exit code returned by the inner SSH command
exit $?