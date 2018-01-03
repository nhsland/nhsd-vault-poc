#!/bin/bash
# Script to decrypt a single row from a CSV using Vault Transit secret backend

# Usage:
# ./poc3-row.sh filename row

# Get path and filename from input arguements
FILEPATH=`echo $1|cut -d'/' -f1`
FILENAME=`echo $1|cut -d'/' -f2`

# Set row from input arguements
REQ_LINENO=$2

transit_cleanup(){
  if [ -f $FILEPATH/$FILENAME-$REQ_LINENO.csv ] ; then
    rm $FILEPATH/$FILENAME-$REQ_LINENO.csv
  fi

  if [ -f $FILEPATH/plain_$FILENAME-$REQ_LINENO.csv ] ; then
    rm $FILEPATH/plain_$FILENAME-$REQ_LINENO.csv
  fi
}

decrypt_row(){
  CIPHER_LINENO=`sed -n "${REQ_LINENO}p" < $FILEPATH/$FILENAME`
  echo $CIPHER_LINENO > $FILEPATH/$FILENAME-$REQ_LINENO.csv
  DECIPHER_LINENO=`./poc3.sh $FILEPATH/$FILENAME-$REQ_LINENO.csv decrypt`
  DECIPHER_LINE=`cat $FILEPATH/plain_$FILENAME-$REQ_LINENO.csv`
}

transit_cleanup;
decrypt_row;

echo "ENCRYPTED: $CIPHER_LINENO"
echo "DECRYPTED: $DECIPHER_LINE"
