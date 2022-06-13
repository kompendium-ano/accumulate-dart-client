// To parse this JSON data, do
//
//     final queryTransactionResponseModel = queryTransactionResponseModelFromJson(jsonString);

import 'dart:convert';

QueryTransactionResponseModel queryTransactionResponseModelFromJson(String str) => QueryTransactionResponseModel.fromJson(json.decode(str));

String queryTransactionResponseModelToJson(QueryTransactionResponseModel data) => json.encode(data.toJson());

class QueryTransactionResponseModel {
  QueryTransactionResponseModel({
    this.jsonrpc,
    this.result,
    this.id,
  });

  String? jsonrpc;
  QueryTransactionResponseModelResult? result;
  int? id;

  factory QueryTransactionResponseModel.fromJson(Map<String, dynamic> json) => QueryTransactionResponseModel(
    jsonrpc: json["jsonrpc"],
    result: QueryTransactionResponseModelResult.fromJson(json["result"]),
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "jsonrpc": jsonrpc,
    "result": result!.toJson(),
    "id": id,
  };
}

class QueryTransactionResponseModelResult {
  QueryTransactionResponseModelResult({
    this.type,
    this.data,
    this.origin,
    this.sponsor,
    this.transactionHash,
    this.txid,
    this.transaction,
    this.signatures,
    this.status,
    this.syntheticTxids,
    this.signatureBooks,
  });

  String? type;
  Data? data;
  String? origin;
  String? sponsor;
  String? transactionHash;
  String? txid;
  Transaction? transaction;
  List<Signature>? signatures;
  Status? status;
  List<String>? syntheticTxids;
  List<SignatureBook>? signatureBooks;

  factory QueryTransactionResponseModelResult.fromJson(Map<String, dynamic> json) => QueryTransactionResponseModelResult(
    type: json["type"],
    data: Data.fromJson(json["data"]),
    origin: json["origin"],
    sponsor: json["sponsor"],
    transactionHash: json["transactionHash"],
    txid: json["txid"],
    transaction: Transaction.fromJson(json["transaction"]),
    signatures: List<Signature>.from(json["signatures"].map((x) => Signature.fromJson(x))),
    status: Status.fromJson(json["status"]),
    syntheticTxids: List<String>.from(json["syntheticTxids"].map((x) => x)),
    signatureBooks: List<SignatureBook>.from(json["signatureBooks"].map((x) => SignatureBook.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "data": data!.toJson(),
    "origin": origin,
    "sponsor": sponsor,
    "transactionHash": transactionHash,
    "txid": txid,
    "transaction": transaction!.toJson(),
    "signatures": List<dynamic>.from(signatures!.map((x) => x.toJson())),
    "status": status!.toJson(),
    "syntheticTxids": List<dynamic>.from(syntheticTxids!.map((x) => x)),
    "signatureBooks": List<dynamic>.from(signatureBooks!.map((x) => x.toJson())),
  };
}

class Data {
  Data({
    this.type,
    this.url,
  });

  String? type;
  String? url;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    type: json["type"],
    url: json["url"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "url": url,
  };
}

class SignatureBook {
  SignatureBook({
    this.authority,
    this.pages,
  });

  String? authority;
  List<Page>? pages;

  factory SignatureBook.fromJson(Map<String, dynamic> json) => SignatureBook(
    authority: json["authority"],
    pages: List<Page>.from(json["pages"].map((x) => Page.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "authority": authority,
    "pages": List<dynamic>.from(pages!.map((x) => x.toJson())),
  };
}

class Page {
  Page({
    this.signer,
    this.signatures,
  });

  Data? signer;
  List<Signature>? signatures;

  factory Page.fromJson(Map<String, dynamic> json) => Page(
    signer: Data.fromJson(json["signer"]),
    signatures: List<Signature>.from(json["signatures"].map((x) => Signature.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "signer": signer!.toJson(),
    "signatures": List<dynamic>.from(signatures!.map((x) => x.toJson())),
  };
}

class Signature {
  Signature({
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
  double? timestamp;
  String? transactionHash;

  factory Signature.fromJson(Map<String, dynamic> json) => Signature(
    type: json["type"],
    publicKey: json["publicKey"],
    signature: json["signature"],
    signer: json["signer"],
    signerVersion: json["signerVersion"],
    timestamp: json["timestamp"].toDouble(),
    transactionHash: json["transactionHash"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "publicKey": publicKey,
    "signature": signature,
    "signer": signer,
    "signerVersion": signerVersion,
    "timestamp": timestamp,
    "transactionHash": transactionHash,
  };
}

class Status {
  Status({
    this.delivered,
    this.result,
    this.initiator,
    this.signers,
  });

  bool? delivered;
  StatusResult? result;
  String? initiator;
  List<Signer>? signers;

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    delivered: json["delivered"],
    result: StatusResult.fromJson(json["result"]),
    initiator: json["initiator"],
    signers: List<Signer>.from(json["signers"].map((x) => Signer.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "delivered": delivered,
    "result": result!.toJson(),
    "initiator": initiator,
    "signers": List<dynamic>.from(signers!.map((x) => x.toJson())),
  };
}

class StatusResult {
  StatusResult({
    this.type,
  });

  String? type;

  factory StatusResult.fromJson(Map<String, dynamic> json) => StatusResult(
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "type": type,
  };
}

class Signer {
  Signer({
    this.type,
    this.url,
    this.lastUsedOn,
    this.nonce,
  });

  String? type;
  String? url;
  double? lastUsedOn;
  double? nonce;

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
    type: json["type"],
    url: json["url"],
    lastUsedOn: json["lastUsedOn"].toDouble(),
    nonce: json["nonce"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "url": url,
    "lastUsedOn": lastUsedOn,
    "nonce": nonce,
  };
}

class Transaction {
  Transaction({
    this.header,
    this.body,
  });

  Header? header;
  Data? body;

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    header: Header.fromJson(json["header"]),
    body: Data.fromJson(json["body"]),
  );

  Map<String, dynamic> toJson() => {
    "header": header!.toJson(),
    "body": body!.toJson(),
  };
}

class Header {
  Header({
    this.principal,
    this.origin,
    this.initiator,
  });

  String? principal;
  String? origin;
  String? initiator;

  factory Header.fromJson(Map<String, dynamic> json) => Header(
    principal: json["principal"],
    origin: json["origin"],
    initiator: json["initiator"],
  );

  Map<String, dynamic> toJson() => {
    "principal": principal,
    "origin": origin,
    "initiator": initiator,
  };
}
