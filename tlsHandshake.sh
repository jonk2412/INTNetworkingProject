#!/bin/bash

# Server IP add ress (passed as argument)
SERVER_IP="${1}"

# Check if serv er IP is provided
if [ -z "$SERVER_IP" ]; then
  echo "Error: Please provide the server IP address as an argument."
  exit 1
fi

# Define endpoints
CLIENT_HELLO_ENDPOINT="/clienthello"
KEY_EXCHANGE_ENDPOINT="/keyexchange"

# Function to send a POST request with JSON body
function send_json_post {
  local url="$1"
  local json_data="$2"

  # shellcheck disable=SC1037
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "$json_data" "http://$SERVER_IP:$8080$url")
  echo "$response"
}

# Step 1: Client Hello
echo "Sending Client Hello..."
client_hello_data='{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}'
server_hello_response=$(send_json_post "$CLIENT_HELLO_ENDPOINT" "$client_hello_data")

# Check if sending Client Hello was successful
if [ -z "$server_hello_response" ]; then
  echo "Error: Failed to send Client Hello."
  exit 2
fi

# Parse server response for session ID and certificate
server_version=$(echo "$server_hello_response" | jq -r '.version')
cipher_suite=$(echo "$server_hello_response" | jq -r '.cipherSuite')
session_id=$(echo "$server_hello_response" | jq -r '.sessionID')
server_cert=$(echo "$server_hello_response" | jq -r '.serverCert')

echo "Server Version: $server_version"
echo "Cipher Suite: $cipher_suite"
echo "Session ID: $session_id"

# Save server certificate
echo "$server_cert" > cert.pem

# Step 3: Server Certificate Verification
echo "Verifying server certificate..."
verification_result=$(openssl verify -CAfile cert-ca-aws.pem cert.pem)

# Check if certificate verification is successful
if [[ "$verification_result" != "OK" ]]; then
  echo "Server Certificate is invalid."
  exit 5
fi

# Step 4: Client-Server Master Key Exchange
echo "Generating random master key..."
master_key=$(openssl rand 32 | base64 -w 0)

echo "Encrypting master key with server certificate..."
encrypted_master_key=$(openssl smime -encrypt -aes-256-cbc -in <(echo "$master_key") -outform DER cert.pem | base64 -w 0)

# Prepare key exchange data
key_exchange_data="{
  \"sessionID\": \"$session_id\",
  \"masterKey\": \"$encrypted_master_key\",
  \"sampleMessage\": \"Hi server, please encrypt me and send to client!\"
}"

# Step 5: Send Encrypted Master Key
echo "Sending encrypted master key and sample message..."
server_response=$(send_json_post "$KEY_EXCHANGE_ENDPOINT" "$key_exchange_data")

# Check if sending key exchange data was successful
if [ -z "$server_response" ]; then
  echo "Error: Failed to send key exchange data."
  exit 3
fi

# Pars e server  response for encrypted sample message
encrypted_sample_message=$(echo "$server_response" | jq -r '.encryptedSampleMessage')

# Step 6: Decrypt Sample Message and  Verify
echo "Decrypting sample message..."
decrypted_sample_message=$(echo "$encrypted_sample_message" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "${master_key}")

# Check if decryption is successful (compare with original sample message)
if [[ "$decrypted_sample_message" != "Hi server, please encrypt me and send to client!" ]]; then
  echo "Server symmetric encryption using the exchanged master-key has failed."
  exit 6
fi

echo "Client-Server TLS handshake has been completed successfully"