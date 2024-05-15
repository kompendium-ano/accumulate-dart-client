import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:convert/convert.dart';
import 'package:accumulate_api/accumulate_api.dart';

Uint8List hexToBytes(String s) {
  return Uint8List.fromList(hex.decode(s));
}

Ed25519KeypairSigner loadSignerFromEncodedKey(String privateKeyBase64) {
  Uint8List privateKey = hexToBytes(privateKeyBase64);
  return Ed25519KeypairSigner.fromKeyRaw(privateKey);
}

Future<String> signTransaction({
  required String privateKeyBase64,
  required String transactionHashHex,
  required String metadataJson,
}) async {
  Ed25519KeypairSigner signer = loadSignerFromEncodedKey(privateKeyBase64);

  // Calculate the hash of the signature metadata
  Uint8List metadataBytes = utf8.encode(metadataJson);
  Uint8List metadataHash =
      crypto.sha256.convert(metadataBytes).bytes as Uint8List;

  // Decode transaction hash
  Uint8List transactionHash =
      Uint8List.fromList(hex.decode(transactionHashHex));

  // Concatenate metadata hash and transaction hash, then hash the result
  Uint8List toSign = Uint8List.fromList([...metadataHash, ...transactionHash]);
  Uint8List finalHash = crypto.sha256.convert(toSign).bytes as Uint8List;

  // Sign the hash
  Uint8List signature = signer.signRaw(finalHash);

  // Convert signature to hex string for display or use in JSON
  String signatureHex = hex.encode(signature);
  return signatureHex;
}

Future<void> main() async {
  String privateKeyBase64 =
      "026e5f575a40cbfec29ef9cf9de63ccc0a9289046fa80750bfb9f2d7626a30274babeda2c1feda94064997737ad7fd613b91e20546db51f97254960455673845";
  String publicKeyHex =
      "4babeda2c1feda94064997737ad7fd613b91e20546db51f97254960455673845";
  String transactionHashHex =
      "1d3395802ecfc268589be1df711f68cec129b535a949f42eb4b181fe87b5438e";

  final sigInfo = SignerInfo();
  sigInfo.type = SignatureType.signatureTypeED25519;
  sigInfo.url = AccURL("acc://custom-adi-name-1714297678838.acme/book/1");
  sigInfo.publicKey = hex.decode(publicKeyHex) as Uint8List?;
  sigInfo.version = 1;
  final timestamp = DateTime.now().microsecondsSinceEpoch;

  final endPoint = "https://kermit.accumulatenetwork.io/v2";
  final client = ACMEClient(endPoint);
  final resp = await client.queryTx("acc://${transactionHashHex}@unknown");
  final rawTx = resp["result"]["transaction"];
  final tx = await unmarshalTx(rawTx, transactionHashHex, timestamp);

  final signer = loadSignerFromEncodedKey(privateKeyBase64);
  final signature = Signature();
  signature.signerInfo = sigInfo;
  signature.signature =
      signer.signRaw(tx.dataForSignature(sigInfo).asUint8List());

  print("Signature: ${hex.encode(signature.signature!)}");
  client.call("execute-direct", {
    "envelope": {
      "transaction": [rawTx],
      "signatures": [
        {
          "type": "ed25519",
          "publicKey": publicKeyHex,
          "signature": hex.encode(signature.signature!),
          "signer": sigInfo.url.toString(),
          "signerVersion": sigInfo.version,
          "timestamp": timestamp,
          "transactionHash": transactionHashHex,
        }
      ],
    },
  });
}

Future<Transaction> unmarshalTx(
    dynamic data, String txHash, int timestamp) async {
  final hopts = HeaderOptions()
    ..initiator = maybeDecodeHex(data["header"]["initiator"])
    ..memo = data["header"]["memo"]
    ..metadata = maybeDecodeHex(data["header"]["metadata"]);

  // timestamp should only be in the signature, not the transaction
  // but SDK requires it in the header options
  hopts.timestamp = timestamp;

  final header = Header(data["header"]["principal"], hopts);
  final payload = decodePayload(data["body"]);
  final tx = Transaction(payload, header);
  final hash2 = hex.encode(tx.hash());
  if (txHash != hash2) {
    throw "hash does not match";
  }
  return tx;
}

int? parseOperationType(String? operationType) {
  if (operationType == null) return null;

  switch (operationType.toLowerCase()) {
    case 'update':
      return KeyPageOperationType.Update;
    case 'remove':
      return KeyPageOperationType.Remove;
    case 'add':
      return KeyPageOperationType.Add;
    case 'setthreshold':
      return KeyPageOperationType.SetThreshold;
    case 'updateallowed':
      return KeyPageOperationType.UpdateAllowed;
    default:
      print("Unknown operation type: $operationType");
      return null;
  }
}

int parseAccountAuthOperationType(String operationType) {
  switch (operationType.toLowerCase()) {
    case 'enable':
      return UpdateAccountAuthActionType.Enable;
    case 'disable':
      return UpdateAccountAuthActionType.Disable;
    case 'addauthority':
      return UpdateAccountAuthActionType.AddAuthority;
    case 'removeauthority':
      return UpdateAccountAuthActionType.RemoveAuthority;
    default:
      print("Unknown operation type: $operationType, defaulting to Disable");
      return UpdateAccountAuthActionType
          .Disable; // Default case to handle unknown types
  }
}

Payload decodePayload(dynamic data) {
  switch (data["type"]) {
    case "writeData":
      if (data["entry"]["type"] != "doubleHash") {
        throw "Unsupported data entry type";
      }
      final params = WriteDataParam()
        ..scratch = data["scratch"] ?? false
        ..writeToState = data["writeToState"] ?? false
        ..data = (data["entry"]["data"] as List<dynamic>?)
                ?.map((s) => hex.decode(s as String))
                .cast<Uint8List>()
                .toList() ??
            [];
      return WriteData(params);

    case "updateKeyPage":
      print("Decoding updateKeyPage payload");
      var operationsData = data["operation"] as List<dynamic>?;
      print("Operations Data: ${jsonEncode(operationsData)}");

      var operations = operationsData?.map((op) {
            print("Processing operation: ${jsonEncode(op)}");
            var keyOperation = KeyOperation()
              ..type = parseOperationType(op["type"] as String?)
              ..key = (op["entry"] != null
                  ? (KeySpec()..delegate = op["entry"]["delegate"])
                  : null);

            print("KeyOperation created with type: ${keyOperation.type}");
            print("Delegate: ${keyOperation.key?.delegate}");

            return keyOperation;
          }).toList() ??
          [];

      print("Total operations processed: ${operations.length}");

      final updateKeyPageParams = UpdateKeyPageParam()
        ..operations = operations
        ..memo = data["memo"] as String?
        ..metadata =
            data["metadata"] != null ? maybeDecodeHex(data["metadata"]) : null;

      print(
          "UpdateKeyPageParam created with memo: ${updateKeyPageParams.memo}");
      if (updateKeyPageParams.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return UpdateKeyPage(updateKeyPageParams);

    case "createIdentity":
      print("Decoding createIdentity payload");
      var url = data["url"] as String?;
      var keyHash = data["keyHash"] as String?;
      var keyBookUrl = data["keyBookUrl"] as String?;
      var metadata = data["metadata"] as String?;

      // Converting keyHash from hex string to Uint8List
      Uint8List? keyHashBytes;
      if (keyHash != null) {
        try {
          keyHashBytes = maybeDecodeHex(keyHash);
        } catch (e) {
          print("Failed to decode keyHash: $e");
        }
      }

      // Creating the CreateIdentityParam object
      var createIdentityParam = CreateIdentityParam()
        ..url = url
        ..keyHash = keyHashBytes
        ..keyBookUrl = keyBookUrl
        ..memo = data["memo"] as String?
        ..metadata = metadata != null ? maybeDecodeHex(metadata) : null;

      print("CreateIdentityParam created with URL: ${createIdentityParam.url}");
      if (createIdentityParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return CreateIdentity(createIdentityParam);

    case "createTokenAccount":
      print("Decoding createTokenAccount payload");
      var url = data["url"] as String?;
      var tokenUrl = data["tokenUrl"] as String?;
      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Handling authorities if present
      var authorities = (data["authorities"] as List<dynamic>?)
          ?.map((authUrl) => AccURL.toAccURL(authUrl))
          .toList(); // Convert each authority URL string to AccURL objects

      // Creating the CreateTokenAccountParam object
      var createTokenAccountParam = CreateTokenAccountParam()
        ..url = url
        ..tokenUrl = tokenUrl
        ..memo = memo
        ..metadata = metadataBytes
        ..authorities = authorities;

      print(
          "CreateTokenAccountParam created with URL: ${createTokenAccountParam.url}");
      if (createTokenAccountParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return CreateTokenAccount(createTokenAccountParam);

    case "sendTokens":
      print("Decoding sendTokens payload");
      var toList = data["to"] as List<dynamic>;
      List<TokenRecipientParam> recipients = toList.map((recipientData) {
        var recipient = TokenRecipientParam();
        recipient.url = recipientData["url"] as String;
        recipient.amount = recipientData["amount"] as String;
        return recipient;
      }).toList();

      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Assuming SendTokensParam can be modified in this manner, matching any required constructor parameters
      var sendTokensParam = SendTokensParam()
        ..to = recipients
        ..memo = memo
        ..metadata = metadataBytes;

      print(
          "SendTokensParam created with recipients: ${sendTokensParam.to.length}");
      if (sendTokensParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return SendTokens(sendTokensParam);

    case "writeDataTo":
      if (data["entry"]["type"] != "doubleHash") {
        throw "Unsupported data entry type";
      }
      final params = WriteDataToParam(
        recipient: data["recipient"],
        data: (data["entry"]["data"] as List<dynamic>?)
                ?.map((s) => hex.decode(s as String))
                .cast<Uint8List>()
                .toList() ??
            [],
      );
      return WriteDataTo(params);

    case "createToken":
      print("Decoding createToken payload");
      var url = data["url"] as String?;
      var symbol = data["symbol"] as String?;
      var precision = data["precision"] as int?;
      var properties = data["properties"];
      var supplyLimit = data["supplyLimit"];
      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Handling optional fields such as properties and authorities
      AccURL? propertiesUrl =
          properties != null ? AccURL.toAccURL(properties) : null;
      List<AccURL>? authorities = (data["authorities"] as List<dynamic>?)
          ?.map((authUrl) => AccURL.toAccURL(authUrl))
          .toList(); // Convert each authority URL string to AccURL objects

      // Create the CreateTokenParam object
      var createTokenParam = CreateTokenParam()
        ..url = url
        ..symbol = symbol ?? "" // Default to an empty string if null
        ..precision = precision ?? 0 // Default to 0 if null
        ..properties = propertiesUrl
        ..supplyLimit = supplyLimit
        ..authorities = authorities
        ..memo = memo
        ..metadata = metadataBytes;

      print("CreateTokenParam created with URL: ${createTokenParam.url}");
      if (createTokenParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return CreateToken(createTokenParam);

    case "issueTokens":
      print("Decoding issueTokens payload");
      // Extract fields from the data
      var toList = data["to"] as List<dynamic>;
      List<TokenRecipientParam> recipients = toList.map((recipientData) {
        var recipient = TokenRecipientParam();
        recipient.url = recipientData["url"] as String;
        recipient.amount = int.parse(recipientData["amount"]
            as String); // Convert string amount to integer
        return recipient;
      }).toList();

      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Assuming IssueTokensParam can be initialized in this manner, matching any required constructor parameters
      var issueTokensParam = IssueTokensParam()
        ..to = recipients
        ..memo = memo
        ..metadata = metadataBytes;

      print(
          "IssueTokensParam created with recipients: ${issueTokensParam.to.length}");
      if (issueTokensParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return IssueTokens(issueTokensParam);

    case "addCredits":
      print("Decoding addCredits payload");
      var recipientUrl = data["recipient"] as String;
      var amount = data["amount"]
          as String; // Amount is expected to be a string that needs to be parsed to int
      var oracle =
          data["oracle"] as int; // Oracle value is directly used as an int
      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Create the AddCreditsParam object
      var addCreditsParam = AddCreditsParam()
        ..recipient = recipientUrl
        ..amount = int.parse(amount) // Parsing the string amount to integer
        ..oracle = oracle
        ..memo = memo
        ..metadata = metadataBytes;

      print("AddCreditsParam created with recipient: $recipientUrl");
      if (addCreditsParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return AddCredits(addCreditsParam);

    case "updateAccountAuth":
      print("Decoding updateAccountAuth payload");
      List<dynamic> operationsData = data["operations"] as List<dynamic>;
      List<UpdateAccountAuthOperation> operations =
          operationsData.map((opData) {
        var op = UpdateAccountAuthOperation();
        op.type = parseAccountAuthOperationType(opData["type"] as String);
        op.authority = opData["authority"] as String;
        return op;
      }).toList();

      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Create the UpdateAccountAuthParam object
      var updateAccountAuthParam = UpdateAccountAuthParam()
        ..operations = operations
        ..memo = memo
        ..metadata = metadataBytes;

      print(
          "UpdateAccountAuthParam created with ${operations.length} operations");
      if (updateAccountAuthParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return UpdateAccountAuth(updateAccountAuthParam);

    case "updateKey":
      print("Decoding updateKey payload");
      var newKeyHashStr = data["newKeyHash"] as String?;
      if (newKeyHashStr == null) {
        throw FormatException("newKeyHash is missing from the payload.");
      }

      Uint8List newKeyHash;
      try {
        newKeyHash = hexToBytes(newKeyHashStr);
        print("New key hash decoded.");
      } catch (e) {
        throw FormatException("Failed to decode new key hash: $e");
      }

      // Extract optional memo field
      var memo = data["memo"] as String?;
      print("Memo: $memo");

      // Handle optional metadata field
      var metadataStr = data["metadata"] as String?;
      Uint8List? metadataBytes;
      if (metadataStr != null) {
        try {
          metadataBytes = hexToBytes(metadataStr);
          print("Metadata (decoded): $metadataBytes");
        } catch (e) {
          throw FormatException("Error decoding metadata: $e");
        }
      } else {
        print("No metadata provided.");
      }

      // Create the UpdateKeyParam object
      var updateKeyParam = UpdateKeyParam()
        ..newKeyHash = newKeyHash
        ..memo = memo
        ..metadata = metadataBytes;

      print("UpdateKeyParam created successfully.");

      // Return the constructed UpdateKey object
      return UpdateKey(updateKeyParam);

    case "burnTokens":
      print("Decoding burnTokens payload");
      var amountStr = data["amount"] as String?;
      if (amountStr == null) {
        throw FormatException("Amount is missing from the burnTokens payload.");
      }

      int amount;
      try {
        amount = int.parse(amountStr);
        print("Amount to burn: $amount");
      } catch (e) {
        throw FormatException("Failed to parse amount: $e");
      }

      // Extract optional memo field
      var memo = data["memo"] as String?;
      print("Memo: $memo");

      // Handle optional metadata field
      var metadataStr = data["metadata"] as String?;
      Uint8List? metadataBytes;
      if (metadataStr != null) {
        try {
          metadataBytes = hexToBytes(metadataStr);
          print("Metadata (decoded): $metadataBytes");
        } catch (e) {
          throw FormatException("Error decoding metadata: $e");
        }
      } else {
        print("No metadata provided.");
      }

      // Create the BurnTokensParam object
      var burnTokensParam = BurnTokensParam()
        ..amount = amount
        ..memo = memo
        ..metadata = metadataBytes;

      print("BurnTokensParam created successfully.");

      // Return the constructed BurnTokens object
      return BurnTokens(burnTokensParam);

    case "createKeyBook":
      print("Decoding createKeyBook payload");

      // Extracting URL from data
      var url = data["url"] as String?;
      if (url == null) {
        throw FormatException("URL is missing from the createKeyBook payload.");
      }
      print("URL: $url");

      // Extracting publicKeyHash and converting from hex
      var publicKeyHashHex = data["publicKeyHash"] as String?;
      Uint8List? publicKeyHash;
      if (publicKeyHashHex != null) {
        try {
          publicKeyHash = hexToBytes(publicKeyHashHex);
          print("Public Key Hash: $publicKeyHashHex");
        } catch (e) {
          throw FormatException("Failed to decode public key hash: $e");
        }
      } else {
        throw FormatException(
            "Public key hash is missing from the createKeyBook payload.");
      }

      // Extracting optional memo field
      var memo = data["memo"] as String?;
      print("Memo: $memo");

      // Handle optional metadata field
      var metadata = data["metadata"] as String?;
      Uint8List? metadataBytes;
      if (metadata != null) {
        try {
          metadataBytes = hexToBytes(metadata);
          print("Metadata (decoded): $metadataBytes");
        } catch (e) {
          throw FormatException("Error decoding metadata: $e");
        }
      } else {
        print("No metadata provided.");
      }

      var createKeyBookParam = CreateKeyBookParam()
        ..url = url
        ..publicKeyHash = publicKeyHash
        ..memo = memo
        ..metadata = metadataBytes;

      print("CreateKeyBookParam created successfully for URL: $url");

      // Extracting authorities if present convert to AccURL list
      var authoritiesData = data["authorities"] as List<dynamic>?;
      if (authoritiesData != null) {
        createKeyBookParam.authorities = authoritiesData
            .map((authUrl) => AccURL.toAccURL(authUrl as String))
            .toList();
        print(
            "Authorities: ${createKeyBookParam.authorities?.map((a) => a.toString()).join(', ')}");
      }

      // Return the constructed CreateKeyBook object
      return CreateKeyBook(createKeyBookParam);

    case "createDataAccount":
      print("Decoding createDataAccount payload");
      var url = data["url"] as String?;
      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      // Convert metadata from hex string to Uint8List if not null
      Uint8List? metadataBytes;
      if (metadata != null) {
        metadataBytes = maybeDecodeHex(metadata);
        print("Metadata (decoded): $metadataBytes");
      }

      // Example handling authorities - update as necessary based on actual data structure
      var authoritiesData = data["authorities"] as List<dynamic>?;
      List<AccURL>? authorities = authoritiesData
          ?.map((authUrl) => AccURL.toAccURL(authUrl as String))
          .toList();

      var createDataAccountParam = CreateDataAccountParam()
        ..url = url
        ..authorities = authorities
        ..memo = memo
        ..metadata = metadataBytes;

      print(
          "CreateDataAccountParam created with URL: ${createDataAccountParam.url}");
      if (createDataAccountParam.metadata != null) {
        print("Metadata decoded successfully");
      } else {
        print("No metadata or failed to decode");
      }

      return CreateDataAccount(createDataAccountParam);

    case "createKeyPage":
      print("Decoding createKeyPage payload");
      var keysData = data["keys"] as List<
          dynamic>?; // Assuming keys is a list of map items with 'keyHash'
      if (keysData == null) {
        throw FormatException(
            "Keys data is missing in the createKeyPage payload.");
      }

      List<Uint8List> keys = [];
      for (var keyData in keysData) {
        var keyHash = keyData["keyHash"] as String?;
        if (keyHash == null) {
          throw FormatException("Key hash is missing from a key data entry.");
        }
        keys.add(hexToBytes(keyHash));
      }

      var memo = data["memo"] as String?;
      var metadata = data["metadata"] as String?;

      Uint8List? metadataBytes;
      if (metadata != null) {
        try {
          metadataBytes = hexToBytes(metadata);
          print("Metadata (decoded): $metadataBytes");
        } catch (e) {
          throw FormatException("Error decoding metadata: $e");
        }
      }

      var createKeyPageParam = CreateKeyPageParam()
        ..keys = keys
        ..memo = memo
        ..metadata = metadataBytes;

      print("CreateKeyPageParam created.");
      return CreateKeyPage(createKeyPageParam);

    default:
      throw "Unsupported transaction type ${data['type']}";
  }
}

Uint8List? maybeDecodeHex(String? hexString) {
  if (hexString == null) return null;
  try {
    return Uint8List.fromList(hex.decode(hexString));
  } catch (e) {
    print("Failed to decode hex: $e");
    return null;
  }
}

bool maybeDecodeBool(dynamic value) {
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return value ?? false;
}

int? maybeDecodeInt(String? s) {
  if (s == null) {
    return null;
  }
  try {
    return int.parse(s);
  } catch (e) {
    print("Failed to parse int: $e");
    return null;
  }
}
