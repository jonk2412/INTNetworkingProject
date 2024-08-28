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

# Extract arguments
bastion_ip="$1"
target_host="$2"
command_to_run="${3:-}"  # Optional command (default empty)
S_KEY="/home/ubuntu/.ssh/newjohn-VMPS.pem"

# Connect to the bastion host using SSH
# Connect to the target host using SSH again

ssh -t -i "$KEY_PATH" ubuntu@$bastion_ip "ssh -i $S_KEY ubuntu@$target_host $command_to_run"


exit $?
# Print the captured output
