#!/bin/bash
# Script to encrypt/decrypt every cell in a CSV using Vault Transit secret backend

# Usage:
# ./poc3.sh filename encrypt|decrypt

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

# Set ACTION for script, either encrypt or decrypt
SCRIPTACTION=$2

# Read in the CSV
while IFS="," read f1 f2 f3 f4 f5 f6 f7
  do
    # VARS for fields from columns
    fROW=$f1

    # Function to base64 encode input
    b64encode(){
      bPATIENTID=`echo $f2|base64`
      bSMOKER=`echo $f3|base64`
      bSTROKE=`echo $f4|base64`
      bLUNGCANCER=`echo $f5|base64`
      bHEARTDISEASE=`echo $f6|base64`
      bRISK=`echo $f7|base64`
    }

    # Function to base64 decode input
    b64decode(){
      while IFS="," read f1 f2 f3 f4 f5 f6 f7
      do
      bPATIENTID=`echo $f2|base64 -d`
      bSMOKER=`echo $f3|base64 -d`
      bSTROKE=`echo $f4|base64 -d`
      bLUNGCANCER=`echo $f5|base64 -d`
      bHEARTDISEASE=`echo $f6|base64 -d`
      bRISK=`echo $f7|base64 -d`
      done < transit_files/decipher_$FILENAME
      rm transit_files/decipher_$FILENAME
    }

    plainVAULTJSON(){
      echo "{" > patient.json
      echo "  \"batch_input\": [" >> patient.json
      echo "    { \"plaintext\": \"$bPATIENTID\" }," >> patient.json
      echo "    { \"plaintext\": \"$bSMOKER\" }," >> patient.json
      echo "    { \"plaintext\": \"$bSTROKE\" }," >> patient.json
      echo "    { \"plaintext\": \"$bLUNGCANCER\" }," >> patient.json
      echo "    { \"plaintext\": \"$bHEARTDISEASE\" }," >> patient.json
      echo "    { \"plaintext\": \"$bRISK\" }" >> patient.json
      echo "  ]" >> patient.json
      echo "}" >> patient.json
    }

    cipherVAULTJSON(){
      echo "{" > patient.json
      echo "  \"batch_input\": [" >> patient.json
      echo "    { \"ciphertext\": \"$f2\" }," >> patient.json
      echo "    { \"ciphertext\": \"$f3\" }," >> patient.json
      echo "    { \"ciphertext\": \"$f4\" }," >> patient.json
      echo "    { \"ciphertext\": \"$f5\" }," >> patient.json
      echo "    { \"ciphertext\": \"$f6\" }," >> patient.json
      echo "    { \"ciphertext\": \"$f7\" }" >> patient.json
      echo "  ]" >> patient.json
      echo "}" >> patient.json
    }

    # Function to encrypt using Vault Transit
    vaultEncrypt(){
      # Send patient.json to Vault
      curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/encrypt/foo > patient_encrypt.json
      # Remove patient.json now
      rm patient.json
      # Process returned json with jq and tr
      encryptROW=`cat patient_encrypt.json | jq --compact-output --raw-output '.data.batch_results | map ([.ciphertext] | join(","))|@text' |tr -d '[' | tr -d ']' | tr -d '"'`
      # Remove patient_encrypt.json now
      rm patient_encrypt.json
      echo "$f1,$encryptROW" >> transit_files/cipher_$FILENAME
    }

    # Function to encrypt using Vault Transit
    vaultDecrypt(){
      curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/decrypt/foo > patient_decrypt.json
      rm patient.json
      decryptROW=`cat patient_decrypt.json | jq --compact-output --raw-output '.data.batch_results | map ([.plaintext] | join(","))|@text' |tr -d '[' | tr -d ']' | tr -d '"'`
      rm patient_decrypt.json
      echo "$f1,$decryptROW" > transit_files/decipher_$FILENAME
    }

    encryptSourceCSV(){
        b64encode; plainVAULTJSON; vaultEncrypt;
    }

    decryptSourceCSV(){
        cipherVAULTJSON; vaultDecrypt; b64decode;
        # Write out CSV
        echo "$fROW,$bPATIENTID,$bSMOKER,$bSTROKE,$bLUNGCANCER,$bHEARTDISEASE,$bRISK" >> transit_files/plain_$FILENAME
    }

    if [ $SCRIPTACTION = encrypt ] ; then
        encryptSourceCSV;
    fi

    if [ $SCRIPTACTION = decrypt ] ; then
        decryptSourceCSV;
    fi
done < $1
