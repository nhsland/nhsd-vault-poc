#!/bin/bash

# Script to encrypt/decrypt every cell in a CSV using Vault Transit secret backend

# Usage:
# ./poc2.sh filename encrypt|decrypt

# Set URL of Vault instance
#VAULT_ADDR="http://127.0.0.1:8200"

# Check for Vault Address
if [[ -z $VAULT_ADDR ]]
then
    failed "ERROR: Please set Vault Address"
    exit 1
fi

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
      bVAR=`echo $1|base64`
    }

    # Function to base64 decode input
    b64decode(){
      bVAR=`echo $1|base64 -d`
    }

    # Function to encrypt using Vault Transit
    vaultEncrypt(){
      echo "{\"plaintext\":\"$1\"}" > patient.json
      vRESPONSE=`curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/encrypt/foo`
      vCIPHER=`echo $vRESPONSE | cut -d '{' -f 3 |cut -d '}' -f 1|cut -d '"' -f4`
      rm patient.json
    }

    # Function to encrypt using Vault Transit
    vaultDecrypt(){
      echo "{\"ciphertext\":\"$1\"}" > patient.json
      vRESPONSE=`curl -s --header "X-Vault-Token: $VAULT_TOKEN" --request POST --data @patient.json $VAULT_ADDR/v1/transit/decrypt/foo`
      vPLAIN=`echo $vRESPONSE | cut -d '{' -f 3 |cut -d '}' -f 1|cut -d '"' -f4`
      rm patient.json
    }

    encryptSourceCSV(){
      # Call functions to encode and crypt each field
      b64encode $fROW; vaultEncrypt $bVAR; eROW=$vCIPHER;
      b64encode $fPATIENTID; vaultEncrypt $bVAR; ePATIENTID=$vCIPHER;
      b64encode $fSMOKER; vaultEncrypt $bVAR; eSMOKER=$vCIPHER;
      b64encode $fSTROKE; vaultEncrypt $bVAR; eSTROKE=$vCIPHER;
      b64encode $fLUNGCANCER; vaultEncrypt $bVAR; eLUNGCANCER=$vCIPHER;
      b64encode $fHEARTDISEASE; vaultEncrypt $bVAR; eHEARTDISEASE=$vCIPHER;
      b64encode $fRISK; vaultEncrypt $bVAR; eRISK=$vCIPHER;

      # Write out CSV
      echo "$fROW,$ePATIENTID,$eSMOKER,$eSTROKE,$eLUNGCANCER,$eHEARTDISEASE,$eRISK" >> cipher_$FILENAME
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
