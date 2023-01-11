#!/bin/bash

#############################################
### Sends ADA from one address to another ###
#############################################

# Enter the UTXO which ADA + transaction fees
# will be spent from
payorUTXO=""

# Amount in ADA which will be converted to lovelace
amountInADA=20
# Address ADA will be sent to
destinationADDR=$()
# Address for change
payorADDR=$()
# Signature file of sender
txSignatory=""

####################################
### No need to change code below ###
####################################

tmpBuild=$(mktemp)

cardano-cli transaction build \
  --testnet-magic 1 \
  --tx-in $payorUTXO \
  --tx-out "$destinationADDR $(($amountInADA*1000000)) lovelace" \
  --change-address $payorADDR \
  --out-file $tmpBuild

[ $? -eq 0 ]  || { echo "Error building transaction"; exit 1; }

tmpSig=$(mktemp)

cardano-cli transaction sign \
  --testnet-magic 1 \
  --tx-body-file $tmpBuild \
  --signing-key-file $txSignatory \
  --out-file $tmpSig

cardano-cli transaction submit \
  --testnet-magic 1 \
  --tx-file $tmpSig

cardano-cli transaction txid --tx-file $tmpSig
