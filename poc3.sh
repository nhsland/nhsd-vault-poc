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


# Set ACTION for script
# Either encrypt or decrypt
SCRIPTACTION=$2

# Read in the CSV
while IFS="," read f1 f2 f3 f4 f5 f6 f7
  do
    # VARS for decrypted columns
    dROW=
    dPATIENTID=
    dSMOKER=
    dSTROKE=
    dLUNGCANCER=
    dHEARTDISEASE=
    dRISK=

    # VARS for encrypted columns
    eROW=
    ePATIENTID=
    eSMOKER=
    eSTROKE=
    eLUNGCANCER=
    eHEARTDISEASE=
    eRISK=

    # VARS for fields from columns
    fROW=$f1
    fPATIENTID=$f2
    fSMOKER=$f3
    fSTROKE=$f4
    fLUNGCANCER=$f5
    fHEARTDISEASE=$f6
    fRISK=$f7

    # Function to base64 encode input
    b64encode(){
      # No need to encode the row number
      # bROW=`echo $f1|base64`
      bPATIENTID=`echo $f2|base64`
      bSMOKER=`echo $f3|base64`
      bSTROKE=`echo $f4|base64`
      bLUNGCANCER=`echo $f5|base64`
      bHEARTDISEASE=`echo $f6|base64`
      bRISK=`echo $f7|base64`
    }

    # Function to base64 decode input
    b64decode(){
      # No need to decode the row number
      # bROW=`echo $f1|base64 -d`
      bPATIENTID=`echo $f2|base64 -d`
      bSMOKER=`echo $f3|base64 -d`
      bSTROKE=`echo $f4|base64 -d`
      bLUNGCANCER=`echo $f5|base64 -d`
      bHEARTDISEASE=`echo $f6|base64 -d`
      bRISK=`echo $f7|base64 -d`
    }

    plainVAULTJSON(){
      echo "{" > patient.json
      echo "  \"batch_input\": [" >> patient.json
      # No need to encrypt the row number
      # echo "    { \"plaintext\": \"$bROW\" }," >> patient.json
      echo "    { \"plaintext\": \"$bPATIENTID\" }," >> patient.json
      echo "    { \"plaintext\": \"$bSMOKER\" }," >> patient.json
      echo "    { \"plaintext\": \"$bSTROKE\" }," >> patient.json
      echo "    { \"plaintext\": \"$bLUNGCANCER\" }," >> patient.json
      echo "    { \"plaintext\": \"$bHEARTDISEASE\" }," >> patient.json
      echo "    { \"plaintext\": \"$bRISK\" }" >> patient.json
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

    # Notes on using jq
    # jq --raw-output '.data.batch_results| .[]|.ciphertext'
    # jq --compact-output --raw-output '.data.batch_results | map ([.ciphertext] | join(", "))'
    # jq --compact-output --raw-output '.data.batch_results | map ([.ciphertext] | join(","))|@text'

    # Function to encrypt using Vault Transit
    # vaultDecrypt(){
    #   echo "{\"ciphertext\":\"$1\"}" > patient.json
    #   vRESPONSE=`curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/decrypt/foo`
    #   vPLAIN=`echo $vRESPONSE | cut -d '{' -f 3 |cut -d '}' -f 1|cut -d '"' -f4`
    #   rm patient.json
    # }

  encryptSourceCSV(){
      b64encode; plainVAULTJSON; vaultEncrypt;
  }

  decryptSourceCSV(){
      # Call functions to encode and crypt each field
      vaultDecrypt $fROW; b64decode $vPLAIN; dROW=$bVAR;
      vaultDecrypt $fPATIENTID; b64decode $vPLAIN; dPATIENTID=$bVAR;
      vaultDecrypt $fSMOKER; b64decode $vPLAIN; dSMOKER=$bVAR;
      vaultDecrypt $fSTROKE; b64decode $vPLAIN; dSTROKE=$bVAR;
      vaultDecrypt $fLUNGCANCER; b64decode $vPLAIN; dLUNGCANCER=$bVAR;
      vaultDecrypt $fHEARTDISEASE; b64decode $vPLAIN; dHEARTDISEASE=$bVAR;
      vaultDecrypt $fRISK; b64decode $vPLAIN; dRISK=$bVAR;

      # Write out CSV
      echo "$fROW,$dPATIENTID,$dSMOKER,$dSTROKE,$dLUNGCANCER,$dHEARTDISEASE,$dRISK" >> plain_$FILENAME
    }

    if [ $SCRIPTACTION = encrypt ] ; then
        encryptSourceCSV;
    fi

    if [ $SCRIPTACTION = decrypt ] ; then
        decryptSourceCSV;
    fi

done < $1
