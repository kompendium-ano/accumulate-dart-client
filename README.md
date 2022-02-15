# Accumulate Dart Client

[![CircleCI](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master.svg?style=svg&circle-token=1ae82503101537a31f2865115486b5d64419274b)](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master)

JSON RPC client for Accumulate blockchain

## Usage

Note: v1 deprecated and soon will be removed from source code. Use v2 only.

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
  // book0 and page0 are default books created during ADI creation
  final resp = await api.callCreateAdi(currAddr, newADI, timestamp, "book0", "page0");
  txhash = resp;
} catch (e) {
  e.toString();
}

```

### 4. Create Keybook with Keypages
```dart
// 4. At first we need to make new keypage
//  4.1 Initial basic model
KeyPage newKeyPage = KeyPage("", keypagePath, "");
newKeyPage.keysRequired = 1;
newKeyPage.keysRequiredOf = 1;

// 4.2 Then we need to assemble list of public keys to add  
String publicKeyFroKeypage = HEX.encode(publicKey.bytes);
List<String> keysToRegister = [""];

// 4.3 Get fresh timestamp
int timestampForKeypage = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

// 4.4 Make Api call
final resp = await api.callKeyPageCreate(newADI, newKeyPage, keysToRegister, timestampForKeypage);

// 4.5 Then we need to add keypage to keybook
//   4.5.1 Prepare KeyNook Structure
String bookName = "my-awesome-book";
String bookPath =  newAdi.path + "/" + bookName;
KeyBook newKeyBook = KeyBook("default", bookPath, "");
kb.parentAdi = newAdi.path;

//   4.5.2 Get fresh timestamp
int timestampForKeybook = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

//  4.5.3 Make Actual call 
final respKb = await api.callKeyBookCreate(newADI, newKeyBook, [newKeyPage], timestampForKeyBook);

```

### 5. Create ADI with non-default keybooks

```dart

// 5. Prepare ADI structure
IdentityADI newADI = IdentityADI("", "acc://cosmonaut1", "");
newADI
  ..sponsor = liteAccount.address
  ..puk = liteAccount.puk
  ..pik = liteAccount.pik
  ..countKeybooks = 1

// 5.1 add timestamp as Nonce value
int timestamp = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

// 5.2
// Here we supply keybook and keypage paths of initially created entities
  final resp = await api.callCreateAdi(currAddr, newADI, timestamp, newKeyBook.path, newKeyPage.path);
```