// lib\src\utils\proof.dart

import 'dart:typed_data';
import 'package:accumulate_api/src/acme_client.dart';
import 'package:accumulate_api/src/model/api_types.dart';
import 'package:accumulate_api/src/model/receipt.dart';
import 'package:accumulate_api/src/model/receipt_model.dart';
import 'package:accumulate_api/src/payload/create_token.dart';
import 'package:accumulate_api/src/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:accumulate_api/src/transaction.dart' as trans;
import 'package:hex/hex.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

Future<Tuple2<dynamic, CreateToken>> constructIssuerProof(ACMEClient client, String tokenUrl) async {
  var txn0url = '${tokenUrl}#txn/0';
  QueryOptions queryOptions = QueryOptions();
  queryOptions.prove = true;

  var res = await client.queryUrl(txn0url, queryOptions);
  print("\n");
  print("$txn0url $res");

  ReceiptModel receiptModel = ReceiptModel.fromMap(res);

  // Log before accessing receiptModel.result.receipts
  print("Logging before accessing receipts: ${receiptModel.result}");
  List<Receipts> receipts = receiptModel.result!.receipts!;
  print("Logging after accessing receipts");

  // Log before accessing transaction
  print("Logging before accessing transaction: ${receiptModel.result}");
  RcpTransaction transaction = receiptModel.result!.transaction!;
  print("Logging after accessing transaction");

  // Check for empty receipts
  if (receipts.isEmpty) {
    print("No proof found");
    return Tuple2("No proof found", CreateToken(CreateTokenParam()));
  }

  Proof proof2 = receipts[0].proof!;
  // Logs are not needed here as we already checked receipts.isEmpty

  // Log before accessing transaction body
  print("Logging before accessing transaction body: ${transaction.body}");
  if (transaction.body!.type != "createToken") {
    print('Expected first transaction of ${tokenUrl} to be createToken but got ${transaction.body!.type}');
  }

  trans.HeaderOptions headerOptions = trans.HeaderOptions();
  headerOptions.initiator = HEX.decode(transaction.header!.initiator!).asUint8List();
  trans.Header header = trans.Header(transaction.header!.principal!, headerOptions);

  CreateTokenParam createTokenParam = CreateTokenParam();
  createTokenParam.url = transaction.body!.url!;
  createTokenParam.symbol = transaction.body!.symbol!;
  createTokenParam.precision = transaction.body!.precision!;

  CreateToken body = CreateToken(createTokenParam);

  trans.Transaction txn = trans.Transaction(body, header);

  // Prove that the body is part of the transaction
  ReceiptEntry entry = ReceiptEntry()
    ..hash = sha256.convert(header.marshalBinary()).bytes.asUint8List()
    ..right = false;

  Receipt receipt = Receipt()
    ..start = body.hash()
    ..startIndex = 0
    ..end = body.hash()
    ..endIndex = 0
    ..anchor = txn.hash()
    ..entries = [entry];

  print("Anchor Res: ${proof2.anchor}");

  // Prove the BVN anchor
  dynamic anchorRes = await client.queryAnchor(proof2.anchor!);

  // Log the response of queryAnchor to see its structure
  print("queryAnchor response: ${jsonEncode(anchorRes)}");

  // Check if the response contains the expected structure
  if (anchorRes["result"] == null || anchorRes["result"]["type"] != "chainEntry" || anchorRes["result"]["mainChain"] == null) {
    print("Invalid anchor response structure: $anchorRes");
    throw Exception("Invalid anchor response structure");
  }

  List<dynamic> mainChainRoots = anchorRes["result"]["mainChain"]["roots"];
  List<dynamic> merkleStateRoots = anchorRes["result"]["merkleState"]["roots"];

  if (mainChainRoots.isEmpty || merkleStateRoots.isEmpty) {
    print("Empty roots in anchor response");
    throw Exception("Empty roots in anchor response");
  }

  // Log individual elements in mainChainRoots and merkleStateRoots
  print("Main Chain Roots:");
  for (int i = 0; i < mainChainRoots.length; i++) {
    print("mainChainRoots[$i]: ${mainChainRoots[i]}");
  }

  print("Merkle State Roots:");
  for (int i = 0; i < merkleStateRoots.length; i++) {
    print("merkleStateRoots[$i]: ${merkleStateRoots[i]}");
  }

  // Ensure proper comparison of roots and anchor
  String? anchorStr = proof2.anchor;
  String? mainChainRootStr = mainChainRoots.firstWhere((element) => element != null, orElse: () => null);

  if (anchorStr == null || mainChainRootStr == null) {
    print("Anchor or main chain root is null");
    throw Exception("Anchor or main chain root is null");
  }

  print("Comparing anchor and main chain root:");
  print("Anchor: $anchorStr");
  print("Main Chain Root: $mainChainRootStr");

  if (anchorStr != mainChainRootStr) {
    print("Mismatch between anchor and main chain root");
    throw Exception("Mismatch between anchor and main chain root");
  }

  // Log and decode the merkleStateRoots
  print("Merkle State Roots: $merkleStateRoots");
  for (var root in merkleStateRoots) {
    if (root != null) {
      Uint8List decodedRoot = HEX.decode(root).asUint8List();
      print("Decoded Root: $decodedRoot");
    }
  }

  Proof proof3 = Proof();
  proof3.entries = [];

  // Populate the proof3 entries from merkleStateRoots
  for (var root in merkleStateRoots) {
    if (root != null) {
      proof3.entries!.add((ReceiptEntry()
        ..hash = HEX.decode(root).asUint8List()
        ..right = false));
    }
  }

  List<ReceiptEntry> entries2 = proof2.entries!
      .map((entr) => ReceiptEntry()
        ..right = entr.right
        ..hash = entr.hash!)
      .toList();

  var encodedAnchor = HEX.decode(proof2.anchor!);
  Receipt receipt2 = Receipt.fromProof(proof2, entries2);

  List<ReceiptEntry> entries3 = proof3.entries!
      .map((entr) => ReceiptEntry()
        ..right = entr.right
        ..hash = entr.hash!)
      .toList();

  // Ensure no null values in entries3
  entries3.removeWhere((entry) => entry.hash == null);

  Receipt receipt3 = Receipt.fromProof(proof3, entries3);

  // Log receipts before combining
  print("Receipt 1: ${receipt}");
  print("Receipt 2: ${receipt2}");
  print("Receipt 3: ${receipt3}");

  // Assemble the full proof
  dynamic receiptR1R2 = combineReceipts(receipt, receipt2);
  dynamic receiptFinal = combineReceipts(receiptR1R2, receipt3);

  return Tuple2(receiptFinal, body);
}

Receipt combineReceipts(Receipt r1, Receipt r2) {
  // Log the anchors being compared
  print("Combining receipts:");
  print("Anchor 1: ${r1.anchor}");
  print("Anchor 2: ${r2.start}");

  dynamic anchorStr = ((r1.anchor is Uint8List) || (r1.anchor is List<int>))
      ? HEX.encode(r1.anchor)
      : r1.anchor;
  dynamic startStr = ((r2.start is Uint8List) || (r2.start is List<int>))
      ? HEX.encode(r2.start)
      : r2.start;

  // Handle empty startStr
  if (startStr == null || startStr.isEmpty) {
    print("Start 2 is empty, using Anchor 1 for comparison");
    startStr = anchorStr;
  }

  // Log the encoded values being compared
  print("Encoded Anchor 1: $anchorStr");
  print("Encoded Start 2: $startStr");

  if (anchorStr != startStr) {
    print("Receipts cannot be combined, anchor ${anchorStr} doesn't match root merkle tree ${startStr}");
    throw Exception("Receipts cannot be combined, anchor ${anchorStr} doesn't match root merkle tree ${startStr}");
  }

  Receipt result = cloneReceipt(r1);
  result.anchor = copyHash(r2.anchor); // Uint8List.fromList(r2.anchor!.toList());

  r2.entries.forEach((e) => result.entries.add(copyReceiptEntry(e)));

  return result;
}

Receipt cloneReceipt(Receipt receipt) {
  Receipt newReceipt = Receipt();
  newReceipt.start = copyHash(receipt.start);
  newReceipt.startIndex = receipt.startIndex;
  newReceipt.end = copyHash(receipt.end);
  newReceipt.endIndex = receipt.endIndex;
  newReceipt.anchor = copyHash(receipt.anchor);
  newReceipt.entries = receipt.entries.map(copyReceiptEntry).toList();

  return newReceipt;
}

ReceiptEntry copyReceiptEntry(ReceiptEntry re) {
  ReceiptEntry result = ReceiptEntry();
  result.hash = copyHash(re.hash);

  if (re.right != null && re.right!) {
    result.right = true;
  }

  return result;
}

Uint8List copyHash(dynamic hash) {
  if ((hash is Uint8List)) {
    return hash;
  }

  if ((hash is List<int>)) {
    return Uint8List.fromList(hash);
  }

  return HEX.decode(hash).asUint8List(); // utf8.encode(hash).asUint8List();
}
