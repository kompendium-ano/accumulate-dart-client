# Accumulate Dart Client

[![CircleCI](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master.svg?style=svg&circle-token=1ae82503101537a31f2865115486b5d64419274b)](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master)

JSON RPC client for Accumulate blockchain

## Usage

### 1. Generate Lite Account

Lite Accounts are simple anonymous accounts, that can be create in following manner

```dart

// Additional setup goes here.
// 1. initiate public/private key from some seed
var privateKey = ed.newKeyFromSeed([0..32]);
var publicKey  = ed.public(privateKey);

// 2. Create New unique ACME url based on Protocol definition
AccumulateURL currentURL = Address.generateAddressViaProtocol(publicKey.bytes, "ACME");
Address liteAccount = Address(currentURL.getPath(), "ACME Account", "");
liteAccount.URL = currentURL;

// 3. Initiate API class instance and register address on the network with faucet
ACMEApiV2 api = ACMEApiV2("https://testnet.accumulatenetwork.io", "v2");
final resp = await api.callFaucet(liteAccount);
```

Note that any Lite Account need to participate in a transaction to be registered on a network.

### 2. Add Credits to Lite Account

```dart
// 4. Credits are converted from ACME token
//   4.1 Get current timestamp in microseconds it works as Nonce and shoud be unique
//       for every transaction
int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

//   4.2 Execute actual credits call
final respCredits = await acmeAPI.callAddCredits(liteAccount, 1000, timestamp);
print('credits - ${respCredits}');
```


### 3. Generate ADI with default keybooks

```dart
// 5. Prepare ADI structure
IdentityADI newADI = IdentityADI("", "acc://cosmonaut1", "");
newADI
  ..sponsor = liteAccount.address
  ..puk = liteAccount.puk
  ..pik = liteAccount.pik
  ..countKeybooks = 1

// 3. add timestamp as Nonce value
int timestamp = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

final acmeAPI = ACMEApiV2("https://testnet.accumulatenetwork.io/", "v2");
String txhash = "";
try {
  final resp = await api.callCreateAdi(currAddr, newADI, timestamp);
  txhash = resp;
} catch (e) {
  e.toString();
}

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

 
