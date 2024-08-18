#!/bin/bash

#chmod +x 05-payment-and-stake-key-pairs.sh

cardano-address recovery-phrase generate > recoveryphrase.txt

cat recoveryphrase.txt | cardano-address key from-recovery-phrase Shelley > root.prv

cardano-address key child 1852H/1815H/0H/0/0    < root.prv > payment-0.prv
cardano-address key public --without-chain-code < payment-0.prv > payment-0.pub

cardano-cli key convert-cardano-address-key \
--shelley-payment-key \
--signing-key-file payment-0.prv \
--out-file payment-0.skey

cardano-cli key verification-key \
--signing-key-file payment-0.skey \
--verification-key-file payment-0.vkey

cardano-address key child 1852H/1815H/0H/2/0 < root.prv > stake.prv
cardano-address key public --without-chain-code < stake.prv > stake.pub

cardano-cli key convert-cardano-address-key \
--shelley-stake-key \
--signing-key-file stake.prv \
--out-file stake.skey

cardano-cli address build --testnet-magic 1 \
--payment-verification-key $(cat payment-0.pub) \
--stake-verification-key $(cat stake.pub) \
--out-file payment-0.addr

cardano-cli stake-address build --testnet-magic 1 \
--stake-verification-key-file stake.pub \
--out-file stake.address
