#!/bin/bash

###Tạo thư mục "tokens" để lưu file liên quan đến tạo native token
mkdir -p tokens
cd tokens/

###Thay thế "Sang Sang" bằng một cái tên khác tùy thích !!!
tokenname=$(echo -n "Sang Sang" | xxd -ps | tr -d '\n')
tokenamount="10000000"
output="0"

###Bước này cần tạo địa chỉ trước đó, có thể chạy script 05-payment-and-stake-key-pairs
address=$(cat payment-0.addr)
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

address=$(cat payment-0.addr)
cardano-cli query utxo --address $address --testnet-magic 1

###Điền các thông tin vừa truy vấn được vào các dòng sau:
txhash="e1775334044df61c550cdbc44293c588cc27b10a97eed749ec81768ba7dc83a6"
txix="0"
funds="100000000"
policyid=$(cat policy/policyID)
output=2000000
receive_address=addr_test1qp8zrwzlmz7f27k3a7syh48vnq69mgqrjd85q25mapnwhacxj7dczm2t5exhwe893s33ftwtektdasvvxsq59788ly8slg2nz2
script="policy/policy.script"

###Build transaction, chuẩn bị cho bước tính toán fee chính xác
cardano-cli conway transaction build \
--testnet-magic 1 \
--tx-in $txhash#$txix \
--tx-out $receive_address+$output+"$tokenamount $policyid.$tokenname" \
--change-address $address \
--mint="$tokenamount $policyid.$tokenname" \
--minting-script-file $script \
--metadata-json-file metadata.json  \
--witness-override 2 \
--out-file tx.raw

###Ký Giao dịch
cardano-cli transaction sign  \
--signing-key-file payment-0.skey  \
--signing-key-file policy/policy.skey  \
--mainnet --tx-body-file tx.raw  \
--out-file tx.signed

###Gửi giao dịch lên mạng lưới
cardano-cli transaction submit --tx-file tx.signed --testnet-magic 1

### Lấy transaction ID
cardano-cli transaction txid --tx-file tx.signed
