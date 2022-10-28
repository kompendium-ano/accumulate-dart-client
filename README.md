
# Accumulate Dart Client


![Pub Version](https://img.shields.io/pub/v/accumulate_api)
![GitHub](https://img.shields.io/github/license/kompendium-ano/accumulate-dart-client)
[![Tests](https://github.com/kompendium-ano/accumulate-dart-client/actions/workflows/dart.yml/badge.svg)](https://github.com/kompendium-ano/accumulate-dart-client/actions/workflows/dart.yml)

Dart client for [Accumulate](https://github.com/AccumulateNetwork/accumulate) blockchain, a novel blockchain network designed to be hugely scalable while maintaining security.
This library supports all API class and basic data types that reflect network types and structures and utility functions to ease up creation of specific requests.

Full API reference available here: https://docs.accumulatenetwork.io/accumulate/developers/api/api-reference

## Installation

With Dart:
```
$ dart pub add accumulate_api
```

With Flutter:
```
$ flutter pub add accumulate_api
```

This will add a line like this to your package's pubspec.yaml (and run an implicit dart pub get):

```
dependencies:
  accumulate_api: any
```
Alternatively, your editor might support dart pub get or flutter pub get. Check the docs for your editor to learn more.
Import it

Now in your Dart code, you can use:
```
import 'package:accumulate_api/accumulate_api.dart';
```

## Usage



### 1. Generate Lite Identity

```dart
ACMEClient client = ACMEClient("https://testnet.accumulatenetwork.io/v2");
var lid = LiteIdentity(Ed25519KeypairSigner.generate());
```

### 2. Add ACME token from Faucet

```dart
ACMEClient client = ACMEClient("https://testnet.accumulatenetwork.io/v2");
var lid = LiteIdentity(Ed25519KeypairSigner.generate());
final res = await client.faucet(lid.acmeTokenAccount);
```


### 3. Add Credits to Lite Identity

```dart
int creditAmount = 60000;
AddCreditsParam addCreditsParam = AddCreditsParam();  
addCreditsParam.recipient = lid.url;  
addCreditsParam.amount = (creditAmount * pow(10, 8)) ~/ oracle;  
addCreditsParam.oracle = await client.valueFromOracle();  
await client.addCredits(lid.url, addCreditsParam, lid);
```


### 4. Send ACME token to another Lite ACME token account

```dart
int sendToken = 10000;
final recipient =  
    LiteIdentity(Ed25519KeypairSigner.generate()).acmeTokenAccount;  
SendTokensParam sendTokensParam = SendTokensParam();  
TokenRecipientParam tokenRecipientParam = TokenRecipientParam();  
tokenRecipientParam.amount = sendToken * pow(10, 8);  
tokenRecipientParam.url = recipient;  
sendTokensParam.to = List<TokenRecipientParam>.from([tokenRecipientParam]);  
await client.sendTokens(lid.acmeTokenAccount, sendTokensParam, lid);

```

### 5. Create ADI
```dart
final identitySigner = Ed25519KeypairSigner.generate();  
var identityUrl = "acc://custom-adi-name";  
final bookUrl = identityUrl + "/custom-book-name";  
  
CreateIdentityParam createIdentityParam = CreateIdentityParam();  
createIdentityParam.url = identityUrl;  
createIdentityParam.keyBookUrl = bookUrl;  
createIdentityParam.keyHash = identitySigner.publicKeyHash();  
await client.createIdentity(lid.url, createIdentityParam, lid);
```


## Contributions
The Library developed by Kompendium, LLC in partnership with [Kelecorix, Inc](https://github.com/kelecorix) and [Sergey Bushnyak](https://github.com/sigrlami). Contributions are welcome, open new PR or submit new issue.

#### Library developers:
* Sergey Bushnyak <sergey.bushnyak@kelecorix.com>
* Jimmy Jose <theguywhomakesapp@gmail.com>

