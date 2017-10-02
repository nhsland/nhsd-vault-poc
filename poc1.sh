#!/bin/bash

# Script to crypt PID, in this case a hospital number, using Vault Transit secret backend

# Set URL of Vault instance
VAULT_ADDR="http://127.0.0.1:8200"

# Check for Vault token
if [[ -z $VAULT_TOKEN ]]
then
    failed "ERROR: Please set Vault token"
fi

# Get path and filename from input arguements
FILEPATH=`echo $1|cut -d'/' -f1`
FILENAME=`echo $1|cut -d'/' -f2`

echo $FILENAME
echo $FILEPATH

# Read in the CSV
while IFS="," read f1 f2 f3 f4 f5 f6 f7
do
  # Base64 encode the hospital number
  DID=`echo $f2 |base64`

  # Create a json file with the base64 encoded hospital number
  echo "{\"plaintext\":\"$DID\"}" > patient.json

  # Send requst to Vault
  RESPONSE=`curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/encrypt/foo`

  # Get cipher from returned JSON
  CIPHER=`echo $RESPONSE | cut -d '{' -f 3 |cut -d '}' -f 1|cut -d '"' -f4`

  # Write out CSV with encrypted hospital number
  echo "$f1,$DID,$CIPHER,$f3,$f4,$f5,$f6,$f7" >> cipher_$FILENAME.csv

  # Remove the temp json file
  rm patient.json

done < $1
