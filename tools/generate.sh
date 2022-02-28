#!/bin/bash

# Change directory to REPO/tools/accumulate
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/accumulate

# Enumerations
go run ./tools/cmd/gen-enum -l ../enums.dart.tmpl -o ../../lib/src/protocol/enums.dart \
    -i KeyPageOperation,TransactionType,SignatureType \
    protocol/enums.yml