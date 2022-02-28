#!/bin/bash

# Change directory to REPO/tools/accumulate
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/accumulate

# Enumerations
go run ./tools/cmd/gen-enum -l ../enums.dart.tmpl -o ../../lib/src/protocol/enums.dart \
    -i KeyPageOperation,TransactionType,SignatureType \
    protocol/enums.yml

# Transactions
go run ./tools/cmd/gen-types -l ../transactions.dart.tmpl -o ../../lib/src/protocol/transactions.dart \
    -i Envelope,Transaction,TransactionHeader,LegacyED25519Signature,ED25519Signature \
    -i CreateIdentity,CreateTokenAccount,SendTokens,CreateDataAccount,WriteData,WriteDataTo,CreateToken,IssueTokens,BurnTokens,CreateKeyPage,CreateKeyBook,AddCredits,UpdateKeyPage,SignPending \
    -i KeySpecParams,TokenRecipient,DataEntry \
    protocol/transactions.yml protocol/general.yml