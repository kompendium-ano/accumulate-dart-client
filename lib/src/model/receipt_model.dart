// lib\src\model\receipt_model.dart

import 'dart:convert';

import 'package:accumulate_api/src/model/receipt.dart';

ReceiptModel receiptModelFromMap(String str) =>
    ReceiptModel.fromMap(json.decode(str));

String receiptModelToMap(ReceiptModel data) => json.encode(data.toMap());

class ReceiptModel {
  ReceiptModel({
    this.jsonrpc,
    this.result,
    this.id,
  });

  String? jsonrpc;
  ReceiptModelResult? result;
  int? id;

  factory ReceiptModel.fromMap(Map<String, dynamic> json) => ReceiptModel(
        jsonrpc: json["jsonrpc"] == null ? null : json["jsonrpc"],
        result: json["result"] == null
            ? null
            : ReceiptModelResult.fromMap(json["result"]),
        id: json["id"] == null ? null : json["id"],
      );

  Map<String, dynamic> toMap() => {
        "jsonrpc": jsonrpc == null ? null : jsonrpc,
        "result": result == null ? null : result!.toMap(),
        "id": id == null ? null : id,
      };
}

class ReceiptModelResult {
  ReceiptModelResult({
    this.type,
    this.mainChain,
    this.merkleState,
    this.data,
    this.origin,
    this.sponsor,
    this.transactionHash,
    this.txid,
    this.transaction,
    this.signatures,
    this.status,
    this.receipts,
    this.signatureBooks,
  });

  String? type;
  MainChain? mainChain;
  MainChain? merkleState;
  RcpData? data;
  String? origin;
  String? sponsor;
  String? transactionHash;
  String? txid;
  RcpTransaction? transaction;
  List<RcpSignature>? signatures;
  Status? status;
  List<Receipts>? receipts;
  List<SignatureBook>? signatureBooks;

  factory ReceiptModelResult.fromMap(Map<String, dynamic> json) =>
      ReceiptModelResult(
        type: json["type"] == null ? null : json["type"],
        mainChain: json["mainChain"] == null
            ? null
            : MainChain.fromMap(json["mainChain"]),
        merkleState: json["merkleState"] == null
            ? null
            : MainChain.fromMap(json["merkleState"]),
        data: json["data"] == null ? null : RcpData.fromMap(json["data"]),
        origin: json["origin"] == null ? null : json["origin"],
        sponsor: json["sponsor"] == null ? null : json["sponsor"],
        transactionHash:
            json["transactionHash"] == null ? null : json["transactionHash"],
        txid: json["txid"] == null ? null : json["txid"],
        transaction: json["transaction"] == null
            ? null
            : RcpTransaction.fromMap(json["transaction"]),
        signatures: json["signatures"] == null
            ? null
            : List<RcpSignature>.from(
                json["signatures"].map((x) => RcpSignature.fromMap(x))),
        status: json["status"] == null ? null : Status.fromMap(json["status"]),
        receipts: json["receipts"] == null
            ? null
            : List<Receipts>.from(
                json["receipts"].map((x) => Receipts.fromMap(x))),
        signatureBooks: json["signatureBooks"] == null
            ? null
            : List<SignatureBook>.from(
                json["signatureBooks"].map((x) => SignatureBook.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
        "mainChain": mainChain == null ? null : mainChain!.toMap(),
        "merkleState": merkleState == null ? null : merkleState!.toMap(),
        "data": data == null ? null : data!.toMap(),
        "origin": origin == null ? null : origin,
        "sponsor": sponsor == null ? null : sponsor,
        "transactionHash": transactionHash == null ? null : transactionHash,
        "txid": txid == null ? null : txid,
        "transaction": transaction == null ? null : transaction!.toMap(),
        "signatures": signatures == null
            ? null
            : List<dynamic>.from(signatures!.map((x) => x.toMap())),
        "status": status == null ? null : status!.toMap(),
        "receipts": receipts == null
            ? null
            : List<dynamic>.from(receipts!.map((x) => x.toMap())),
        "signatureBooks": signatureBooks == null
            ? null
            : List<dynamic>.from(signatureBooks!.map((x) => x.toMap())),
      };
}

class RcpData {
  RcpData({
    this.type,
    this.url,
    this.symbol,
    this.precision,
  });

  String? type;
  String? url;
  String? symbol;
  int? precision;

  factory RcpData.fromMap(Map<String, dynamic> json) => RcpData(
        type: json["type"] == null ? null : json["type"],
        url: json["url"] == null ? null : json["url"],
        symbol: json["symbol"] == null ? null : json["symbol"],
        precision: json["precision"] == null ? null : json["precision"],
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
        "url": url == null ? null : url,
        "symbol": symbol == null ? null : symbol,
        "precision": precision == null ? null : precision,
      };
}

class MainChain {
  MainChain({
    this.roots,
  });

  List<String>? roots;

  factory MainChain.fromMap(Map<String, dynamic> json) => MainChain(
        roots: json["roots"] == null
            ? null
            : List<String>.from(json["roots"].map((x) => x)),
      );

  Map<String, dynamic> toMap() => {
        "roots":
            roots == null ? null : List<dynamic>.from(roots!.map((x) => x)),
      };
}

class Receipts {
  Receipts({
    this.localBlock,
    this.proof,
    this.receipt,
    this.account,
    this.chain,
  });

  int? localBlock;
  Proof? proof;
  Proof? receipt;
  String? account;
  String? chain;

  factory Receipts.fromMap(Map<String, dynamic> json) => Receipts(
        localBlock: json["localBlock"] == null ? null : json["localBlock"],
        proof: json["proof"] == null ? null : Proof.fromMap(json["proof"]),
        receipt:
            json["receipt"] == null ? null : Proof.fromMap(json["receipt"]),
        account: json["account"] == null ? null : json["account"],
        chain: json["chain"] == null ? null : json["chain"],
      );

  Map<String, dynamic> toMap() => {
        "localBlock": localBlock == null ? null : localBlock,
        "proof": proof == null ? null : proof!.toMap(),
        "receipt": receipt == null ? null : receipt!.toMap(),
        "account": account == null ? null : account,
        "chain": chain == null ? null : chain,
      };
}

class Proof {
  Proof({
    this.start,
    this.startIndex,
    this.end,
    this.endIndex,
    this.anchor,
    this.entries,
  });

  String? start;
  int? startIndex;
  String? end;
  int? endIndex;
  String? anchor;
  List<ReceiptEntry>? entries; // Use ReceiptEntry here instead of Entry

  factory Proof.fromMap(Map<String, dynamic> json) => Proof(
        start: json["start"] == null ? null : json["start"],
        startIndex: json["startIndex"] == null ? null : json["startIndex"],
        end: json["end"] == null ? null : json["end"],
        endIndex: json["endIndex"] == null ? null : json["endIndex"],
        anchor: json["anchor"] == null ? null : json["anchor"],
        entries: json["entries"] == null
            ? null
            : List<ReceiptEntry>.from(json["entries"]
                .map((x) => ReceiptEntry.fromMap(x))), // Use ReceiptEntry here
      );

  Map<String, dynamic> toMap() => {
        "start": start == null ? null : start,
        "startIndex": startIndex == null ? null : startIndex,
        "end": end == null ? null : end,
        "endIndex": endIndex == null ? null : endIndex,
        "anchor": anchor == null ? null : anchor,
        "entries": entries == null
            ? null
            : List<dynamic>.from(
                entries!.map((x) => x.toMap())), // Use ReceiptEntry here
      };
}

class Entry {
  Entry({
    this.hash,
    this.right,
  });

  String? hash;
  bool? right;

  factory Entry.fromMap(Map<String, dynamic> json) => Entry(
        hash: json["hash"] == null ? null : json["hash"],
        right: json["right"] == null ? null : json["right"],
      );

  Map<String, dynamic> toMap() => {
        "hash": hash == null ? null : hash,
        "right": right == null ? null : right,
      };
}

class SignatureBook {
  SignatureBook({
    this.authority,
    this.pages,
  });

  String? authority;
  List<Page>? pages;

  factory SignatureBook.fromMap(Map<String, dynamic> json) => SignatureBook(
        authority: json["authority"] == null ? null : json["authority"],
        pages: json["pages"] == null
            ? null
            : List<Page>.from(json["pages"].map((x) => Page.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "authority": authority == null ? null : authority,
        "pages": pages == null
            ? null
            : List<dynamic>.from(pages!.map((x) => x.toMap())),
      };
}

class Page {
  Page({
    this.signer,
    this.signatures,
  });

  PageSigner? signer;
  List<RcpSignature>? signatures;

  factory Page.fromMap(Map<String, dynamic> json) => Page(
        signer:
            json["signer"] == null ? null : PageSigner.fromMap(json["signer"]),
        signatures: json["signatures"] == null
            ? null
            : List<RcpSignature>.from(
                json["signatures"].map((x) => RcpSignature.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "signer": signer == null ? null : signer!.toMap(),
        "signatures": signatures == null
            ? null
            : List<dynamic>.from(signatures!.map((x) => x.toMap())),
      };
}

class RcpSignature {
  RcpSignature({
    this.type,
    this.publicKey,
    this.signature,
    this.signer,
    this.signerVersion,
    this.timestamp,
    this.transactionHash,
  });

  String? type;
  String? publicKey;
  String? signature;
  String? signer;
  int? signerVersion;
  int? timestamp;
  String? transactionHash;

  factory RcpSignature.fromMap(Map<String, dynamic> json) => RcpSignature(
        type: json["type"] == null ? null : json["type"],
        publicKey: json["publicKey"] == null ? null : json["publicKey"],
        signature: json["signature"] == null ? null : json["signature"],
        signer: json["signer"] == null ? null : json["signer"],
        signerVersion:
            json["signerVersion"] == null ? null : json["signerVersion"],
        timestamp: json["timestamp"] == null ? null : json["timestamp"],
        transactionHash:
            json["transactionHash"] == null ? null : json["transactionHash"],
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
        "publicKey": publicKey == null ? null : publicKey,
        "signature": signature == null ? null : signature,
        "signer": signer == null ? null : signer,
        "signerVersion": signerVersion == null ? null : signerVersion,
        "timestamp": timestamp == null ? null : timestamp,
        "transactionHash": transactionHash == null ? null : transactionHash,
      };
}

class PageSigner {
  PageSigner({
    this.type,
    this.url,
    this.acceptThreshold,
  });

  String? type;
  String? url;
  int? acceptThreshold;

  factory PageSigner.fromMap(Map<String, dynamic> json) => PageSigner(
        type: json["type"] == null ? null : json["type"],
        url: json["url"] == null ? null : json["url"],
        acceptThreshold:
            json["acceptThreshold"] == null ? null : json["acceptThreshold"],
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
        "url": url == null ? null : url,
        "acceptThreshold": acceptThreshold == null ? null : acceptThreshold,
      };
}

class Status {
  Status({
    this.txId,
    this.code,
    this.delivered,
    this.codeNum,
    this.result,
    this.received,
    this.initiator,
    this.signers,
  });

  String? txId;
  String? code;
  bool? delivered;
  int? codeNum;
  StatusResult? result;
  int? received;
  String? initiator;
  List<SignerElement>? signers;

  factory Status.fromMap(Map<String, dynamic> json) => Status(
        txId: json["txID"] == null ? null : json["txID"],
        code: json["code"] == null ? null : json["code"],
        delivered: json["delivered"] == null ? null : json["delivered"],
        codeNum: json["codeNum"] == null ? null : json["codeNum"],
        result: json["result"] == null
            ? null
            : StatusResult.fromMap(json["result"]),
        received: json["received"] == null ? null : json["received"],
        initiator: json["initiator"] == null ? null : json["initiator"],
        signers: json["signers"] == null
            ? null
            : List<SignerElement>.from(
                json["signers"].map((x) => SignerElement.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "txID": txId == null ? null : txId,
        "code": code == null ? null : code,
        "delivered": delivered == null ? null : delivered,
        "codeNum": codeNum == null ? null : codeNum,
        "result": result == null ? null : result!.toMap(),
        "received": received == null ? null : received,
        "initiator": initiator == null ? null : initiator,
        "signers": signers == null
            ? null
            : List<dynamic>.from(signers!.map((x) => x.toMap())),
      };
}

class StatusResult {
  StatusResult({
    this.type,
  });

  String? type;

  factory StatusResult.fromMap(Map<String, dynamic> json) => StatusResult(
        type: json["type"] == null ? null : json["type"],
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
      };
}

class SignerElement {
  SignerElement({
    this.type,
    this.keyBook,
    this.url,
    this.acceptThreshold,
    this.threshold,
    this.version,
  });

  String? type;
  String? keyBook;
  String? url;
  int? acceptThreshold;
  int? threshold;
  int? version;

  factory SignerElement.fromMap(Map<String, dynamic> json) => SignerElement(
        type: json["type"] == null ? null : json["type"],
        keyBook: json["keyBook"] == null ? null : json["keyBook"],
        url: json["url"] == null ? null : json["url"],
        acceptThreshold:
            json["acceptThreshold"] == null ? null : json["acceptThreshold"],
        threshold: json["threshold"] == null ? null : json["threshold"],
        version: json["version"] == null ? null : json["version"],
      );

  Map<String, dynamic> toMap() => {
        "type": type == null ? null : type,
        "keyBook": keyBook == null ? null : keyBook,
        "url": url == null ? null : url,
        "acceptThreshold": acceptThreshold == null ? null : acceptThreshold,
        "threshold": threshold == null ? null : threshold,
        "version": version == null ? null : version,
      };
}

class RcpTransaction {
  RcpTransaction({
    this.header,
    this.body,
  });

  RcpHeader? header;
  RcpData? body;

  factory RcpTransaction.fromMap(Map<String, dynamic> json) => RcpTransaction(
        header:
            json["header"] == null ? null : RcpHeader.fromMap(json["header"]),
        body: json["body"] == null ? null : RcpData.fromMap(json["body"]),
      );

  Map<String, dynamic> toMap() => {
        "header": header == null ? null : header!.toMap(),
        "body": body == null ? null : body!.toMap(),
      };
}

class RcpHeader {
  RcpHeader({
    this.principal,
    this.initiator,
  });

  String? principal;
  String? initiator;

  factory RcpHeader.fromMap(Map<String, dynamic> json) => RcpHeader(
        principal: json["principal"] == null ? null : json["principal"],
        initiator: json["initiator"] == null ? null : json["initiator"],
      );

  Map<String, dynamic> toMap() => {
        "principal": principal == null ? null : principal,
        "initiator": initiator == null ? null : initiator,
      };
}
