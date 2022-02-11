# Accumulate Dart Client

[![CircleCI](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master.svg?style=svg&circle-token=1ae82503101537a31f2865115486b5d64419274b)](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master)

JSON RPC client for Accumulate blockchain

## Usage

### 1. Generate Lite Account

Lite Accounts are simple anonymous accounts, that can be create in following manner

```dart
// Additional setup goes here.
// 1. initiate public/private keypage
var privateKey = ed.newKeyFromSeed([0..32]);
var publicKey  = ed.public(privateKey);

// 2. Create New unique ACME url based on Protocol definition
AccumulateURL currentURL = Address.generateAddressViaProtocol(publicKey.bytes, "ACME");
Address liteAccount = Address(currentURL.getPath(), "ACME Account", "");
liteAccount.URL = currentURL;

// 3. Initiate API class instance and register address on the network with faucet
ACMIApiV2 api = ACMIApiV2();
final resp = await api.callFaucet(liteAccount);
```

Note that any Lite Account need to participate in a transaction to be registered on a network.

### 2. Add Credits to Lite Account

```dart
```


### 3. Generate ADI with default keybooks

```dart
```


### 4. Generate ADI with non-default keybooks

```dart
```


### 5. Generate ADI Token Account

```dart
```


### 6. Make Token Transactions

```dart
```

 
