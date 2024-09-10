#!/bin/bash

###Tạo thư mục "tokens" để lưu file liên quan đến tạo native token
mkdir -p tokens
cd tokens/

###Thay thế "Sang Sang" bằng một cái tên khác tùy thích !!!
tokenname=$(echo -n "Sang Sang" | xxd -ps | tr -d '\n')
tokenamount="10000000"
output="0"

###Bước này cần tạo địa chỉ trước đó, có thể chạy script 05-payment-and-stake-key-pairs
address=$(cat ../payment-0.addr)
###Tạo địa chỉ thanh toán xong thì gửi vào đó một chút tADA để thực hiện mint token

cardano-cli query protocol-parameters --testnet-magic 1 --out-file protocol.json

###Tạo thư mục Policy để lưu các file liên quan đến Policy
mkdir -p policy

cardano-cli address key-gen \
    --verification-key-file policy/policy.vkey \
    --signing-key-file policy/policy.skey

###Tạo policy script cho token sẽ mint
echo "{" > policy/policy.script 
echo "  \"keyHash\": \"$(cardano-cli address key-hash --payment-verification-key-file policy/policy.vkey)\"," >> policy/policy.script 
echo "  \"type\": \"sig\"" >> policy/policy.script 
echo "}" >> policy/policy.script

###Tạo policyID từ policy.script
cardano-cli transaction policyid --script-file policy/policy.script > policy/policyID

address=$(cat ../payment-0.address)
cardano-cli query utxo --address $address --testnet-magic 1

###Điền các thông tin vừa truy vấn được vào các dòng sau:
txhash="1cd8e407861756cd6f58b92321ae75ac206460d78a327db5e8f1e26f529bebb0"
txix="0"
funds="100000000"
policyid=$(cat policy/policyID) 

###Xây dựng transaction ban đầu để tính toán fee hợp lý
cardano-cli transaction build-raw \
    --fee 0\
    --tx-in $txhash#$txix \
    --tx-out $address+$output+"$tokenamount $policyid.$tokenname" \
    --mint "$tokenamount $policyid.$tokenname" \
    --minting-script-file policy/policy.script \
    --out-file txmintraw

fee=$(cardano-cli transaction calculate-min-fee --tx-body-file txmintraw --tx-in-count 1 --tx-out-count 1 --witness-count 2 --testnet-magic 1 --protocol-params-file protocol.json | cut -d " " -f1)
echo "fee= $fee"

output=$(expr $funds - $fee)
echo "output= $output"

###Xây dựng lại transaction sau khi đã biết chính xác fee và số tiền chuyển ra
cardano-cli transaction build-raw \
    --fee $fee  \
    --tx-in $txhash#$txix  \
    --tx-out $address+$output+"$tokenamount $policyid.$tokenname" \
    --mint "$tokenamount $policyid.$tokenname" \
    --minting-script-file policy/policy.script \
    --out-file txmintraw      

###Ký giao dịch
cardano-cli transaction sign  \
    --signing-key-file ../payment-0.skey  \
    --signing-key-file policy/policy.skey  \
    --testnet-magic 1 \
    --tx-body-file txmintraw  \
    --out-file txmintsigned

###Gửi giao dịch lên mạng lưới
cardano-cli transaction submit \
    --tx-file txmintsigned \
    --testnet-magic 1

### Lấy transaction ID
cardano-cli transaction txid --tx-file txmintsigned
