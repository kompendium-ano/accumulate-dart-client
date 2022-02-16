# Accumulate Dart Client

[![CircleCI](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master.svg?style=svg&circle-token=1ae82503101537a31f2865115486b5d64419274b)](https://circleci.com/gh/kompendium-ano/accumulate-dart-client/tree/master)

JSON RPC client for Accumulate blockchain, supports all API calss and basic data types that reflect network types and structures.

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
List<String> keysToRegister = [publicKeyForKeypage]; 

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

### 6. Create ADI Token Account
```dart
// 6. Prepare Token Account structure
// 6.1 Understand current tip of Keypage chain, represented as int value, called "height"
int keyPageHeight = 1;
final kbData = await api.callQuery(newKeypage.path);
kbData.hashCode;
if (kbData != null) {
  keyPageHeight = kbData.nonce;
}

// 6.2 Indicate keypair the we use to sign, should be from keypage
String kpuk = HEX.encode(publicKey.bytes);
String kpik = HEX.encode(privateKey.bytes);

// 6.3 add timestamp as Nonce value
int timestampForTokenAccount = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

// 6.4 Provide name for account and related basic structures
final resp = await api.callCreateTokenAccount(liteAccount, newAdi, "my-token-acc", currentKeyBook.path,
timestampForTokenAccount, kpuk, kpik, keyPageHeight);

```

## 7 Create ADI Data Account
```dart
// 7. Prepare Data Account structure
// 7.1 Understand current tip of Keypage chain, represented as int value, called "height"
int keyPageHeight = 1;
final kbData = await api.callQuery(newKeypage.path);
kbData.hashCode;
if (kbData != null) {
  keyPageHeight = kbData.nonce;
}

// 7.2 Indicate keypair the we use to sign, should be from keypage
String kpuk = HEX.encode(publicKey.bytes);
String kpik = HEX.encode(privateKey.bytes);

// 7.3 add timestamp as Nonce value
int timestampForTokenAccount = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

// 7.4 Provide name for account and related basic structures
final resp = await api.callCreateDataAccount(liteAccount, newAdi, "my-token-acc", currentKeyBook.path,
timestampForTokenAccount, kpuk, kpik, keyPageHeight);
```

### 8. Make Token Transactions
```dart

// 8.1 Prepare recepient structure
Address liteAccountRecepient = Address("acc://065f61a515b09cafd98307616393f783528433731b58c306/acme","","")

// 8.2 add timestamp as Nonce value
int timestampForTransaction = DateTime
    .now()
    .toUtc()
    .millisecondsSinceEpoch;

// 8.3 Provide recipient structure and token label
final resp =
          await api.callCreateTokenTransaction
                  ( liteAccount
                  , liteAccountRecepient
                  , 10000
                  , timestampForTransaction
                  , "acme");
```

### 9. Write Data to ADI Data Account
```dart
```

## Contributions

The Library developed by Kompendium, LLC in partnership with Kelecorix, Inc and Sergey Bushnyak(@sigrlami).
If you're an active user or find it useful we strongly encourage you to support our efforts and ensure long maintenance by contributing a small donation to one of the following cryptocurrency addresses:

- BTC: 39oVXpsgsyW8ZgzsnX3sV7HLdtXWfT96qN
- ETH: 0x9cDBA6bb44772259B3A3fb89cf233A147a720f34
- FCT: FA38cwer93mmPw1HxjScLmK1yF9iJTu5P87T2vdkbuLovm2YXyss