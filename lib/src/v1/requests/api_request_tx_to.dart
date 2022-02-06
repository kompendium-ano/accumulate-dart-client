import 'dart:convert';

import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_tx_to.dart';

import 'adi/api_request_adi.dart';
import 'api_request_credit.dart';
import 'api_request_keybook.dart';
import 'api_request_keypage.dart';
import 'api_request_keypage_update.dart';
import 'api_request_token_account.dart';

class ApiRequestRaw {
  ApiRequestRaw({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx tx;
  bool wait;

  factory ApiRequestRaw.fromRawJson(String str) => ApiRequestRaw.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw(tx: ApiRequestRawTx.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_ADI {
  ApiRequestRaw_ADI({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_ADI tx;
  bool wait;

  factory ApiRequestRaw_ADI.fromRawJson(String str) => ApiRequestRaw_ADI.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_ADI.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_ADI(tx: ApiRequestRawTx_ADI.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_TokenAccount {
  ApiRequestRaw_TokenAccount({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_TokenAccount tx;
  bool wait;

  factory ApiRequestRaw_TokenAccount.fromRawJson(String str) => ApiRequestRaw_TokenAccount.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_TokenAccount.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_TokenAccount(tx: ApiRequestRawTx_TokenAccount.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_KeyBook {
  ApiRequestRaw_KeyBook({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_KeyBook tx;
  bool wait;

  factory ApiRequestRaw_KeyBook.fromRawJson(String str) => ApiRequestRaw_KeyBook.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_KeyBook.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_KeyBook(tx: ApiRequestRawTx_KeyBook.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_KeyPage {
  ApiRequestRaw_KeyPage({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_KeyPage tx;
  bool wait;

  factory ApiRequestRaw_KeyPage.fromRawJson(String str) => ApiRequestRaw_KeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_KeyPage.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_KeyPage(tx: ApiRequestRawTx_KeyPage.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_KeyPageUpdate {
  ApiRequestRaw_KeyPageUpdate({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_KeyPageUpdate tx;
  bool wait;

  factory ApiRequestRaw_KeyPageUpdate.fromRawJson(String str) => ApiRequestRaw_KeyPageUpdate.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_KeyPageUpdate.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_KeyPageUpdate(tx: ApiRequestRawTx_KeyPageUpdate.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRaw_Credits {
  ApiRequestRaw_Credits({
    this.tx,
    this.wait,
  });

  ApiRequestRawTx_Credits tx;
  bool wait;

  factory ApiRequestRaw_Credits.fromRawJson(String str) => ApiRequestRaw_Credits.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRaw_Credits.fromJson(Map<String, dynamic> json) =>
      ApiRequestRaw_Credits(tx: ApiRequestRawTx_Credits.fromJson(json["tx"]), wait: json["wait"]);

  Map<String, dynamic> toJson() => {
        "tx": tx.toJson(),
        "wait": wait,
      };
}

class ApiRequestRawTx {
  ApiRequestRawTx({this.sponsor, this.data, this.signer, this.sig, this.keyPage});

  String sponsor;
  ApiRequestTxToData data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx.fromRawJson(String str) => ApiRequestRawTx.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx.fromJson(Map<String, dynamic> json) => ApiRequestRawTx(
      sponsor: json["sponsor"],
      data: ApiRequestTxToData.fromJson(json["data"]),
      signer: Signer.fromJson(json["signer"]),
      sig: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keyPage.toJson(),
      };
}

class ApiRequestRawTxKeyPage {
  ApiRequestRawTxKeyPage({
    this.height,
    this.index,
  });

  int height;
  int index;

  factory ApiRequestRawTxKeyPage.fromRawJson(String str) => ApiRequestRawTxKeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTxKeyPage.fromJson(Map<String, dynamic> json) => ApiRequestRawTxKeyPage(
        height: json["height"],
        index: json["index"],
      );

  Map<String, dynamic> toJson() => {
        "height": height,
        "index": index,
      };
}

class ApiRequestRawTx_ADI {
  ApiRequestRawTx_ADI({this.sponsor, this.data, this.signer, this.sig, this.keyPage});

  String sponsor;
  ApiRequestADI data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_ADI.fromRawJson(String str) => ApiRequestRawTx_ADI.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_ADI.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_ADI(
      sponsor: json["sponsor"],
      data: ApiRequestADI.fromJson(json["data"]),
      signer: Signer.fromJson(json["signer"]),
      sig: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keyPage.toJson(),
      };
}

class ApiRequestRawTx_TokenAccount {
  ApiRequestRawTx_TokenAccount({this.sponsor, this.data, this.signer, this.sig, this.keyPage});

  String sponsor;
  ApiRequestTokenAccount data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_TokenAccount.fromRawJson(String str) =>
      ApiRequestRawTx_TokenAccount.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_TokenAccount.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_TokenAccount(
      sponsor: json["sponsor"],
      data: ApiRequestTokenAccount.fromJson(json["data"]),
      signer: Signer.fromJson(json["signer"]),
      sig: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keyPage.toJson(),
      };
}

class ApiRequestRawTx_KeyBook {
  ApiRequestRawTx_KeyBook({this.sponsor, this.data, this.signer, this.sig, this.keyPage});

  String sponsor;
  ApiRequestKeyBook data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keyPage;

  factory ApiRequestRawTx_KeyBook.fromRawJson(String str) => ApiRequestRawTx_KeyBook.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyBook.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyBook(
      sponsor: json["sponsor"],
      data: ApiRequestKeyBook.fromJson(json["data"]),
      signer: Signer.fromJson(json["signer"]),
      sig: json["sig"],
      keyPage: ApiRequestRawTxKeyPage.fromJson(json["keyPage"]));

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keyPage.toJson(),
      };
}

class ApiRequestRawTx_KeyPage {
  ApiRequestRawTx_KeyPage({this.sponsor, this.data, this.signer, this.sig, this.keypageInfo});

  String sponsor;
  ApiRequestKeyPage data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keypageInfo; // this is technical info

  factory ApiRequestRawTx_KeyPage.fromRawJson(String str) => ApiRequestRawTx_KeyPage.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyPage.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyPage(
        sponsor: json["sponsor"],
        data: ApiRequestKeyPage.fromJson(json["data"]),
        signer: Signer.fromJson(json["signer"]),
        sig: json["sig"],
        keypageInfo: ApiRequestRawTxKeyPage.fromJson(json['keyPage']),
      );

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keypageInfo.toJson(),
      };
}

class ApiRequestRawTx_KeyPageUpdate {
  ApiRequestRawTx_KeyPageUpdate({this.sponsor, this.data, this.signer, this.sig, this.keypageInfo});

  String sponsor;
  ApiRequestKeyPageUpdate data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keypageInfo; // this is technical info

  factory ApiRequestRawTx_KeyPageUpdate.fromRawJson(String str) =>
      ApiRequestRawTx_KeyPageUpdate.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_KeyPageUpdate.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_KeyPageUpdate(
        sponsor: json["sponsor"],
        data: ApiRequestKeyPageUpdate.fromJson(json["data"]),
        signer: Signer.fromJson(json["signer"]),
        sig: json["sig"],
        keypageInfo: ApiRequestRawTxKeyPage.fromJson(json['keyPage']),
      );

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keypageInfo.toJson(),
      };
}

class ApiRequestRawTx_Credits {
  ApiRequestRawTx_Credits({this.sponsor, this.data, this.signer, this.sig, this.keypageInfo});

  String sponsor;
  ApiRequestCredits data;
  Signer signer;
  String sig;
  ApiRequestRawTxKeyPage keypageInfo; // this is technical info

  factory ApiRequestRawTx_Credits.fromRawJson(String str) => ApiRequestRawTx_Credits.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestRawTx_Credits.fromJson(Map<String, dynamic> json) => ApiRequestRawTx_Credits(
        sponsor: json["sponsor"],
        data: ApiRequestCredits.fromJson(json["data"]),
        signer: Signer.fromJson(json["signer"]),
        sig: json["sig"],
        keypageInfo: ApiRequestRawTxKeyPage.fromJson(json['keyPage']),
      );

  Map<String, dynamic> toJson() => {
        "sponsor": sponsor,
        "data": data.toJson(),
        "signer": signer.toJson(),
        "sig": sig,
        "keyPage": keypageInfo.toJson(),
      };
}

class ApiRequestTxToData {
  ApiRequestTxToData({
    this.from,
    this.to,
    this.hash,
  });

  String hash;
  String from;
  List<ApiRequestTxToDataTo> to;

  factory ApiRequestTxToData.fromRawJson(String str) => ApiRequestTxToData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToData.fromJson(Map<String, dynamic> json) => ApiRequestTxToData(
        from: json["from"],
        hash: json["hash"],
        to: List<ApiRequestTxToDataTo>.from(json["to"].map((x) => ApiRequestTxToDataTo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "from": from,
        "hash": hash,
        "to": List<dynamic>.from(to.map((x) => x.toJson())),
      };
}

class ApiRequestTxToDataTo {
  ApiRequestTxToDataTo({
    this.url,
    this.amount,
  });

  String url;
  int amount;

  factory ApiRequestTxToDataTo.fromRawJson(String str) => ApiRequestTxToDataTo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ApiRequestTxToDataTo.fromJson(Map<String, dynamic> json) => ApiRequestTxToDataTo(
        url: json["url"],
        amount: json["amount"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "amount": amount,
      };
}

class Signer {
  Signer({
    this.nonce,
    this.publicKey,
  });

  int nonce; //timestamp??
  String publicKey;

  factory Signer.fromRawJson(String str) => Signer.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Signer.fromJson(Map<String, dynamic> json) => Signer(
        nonce: json["nonce"],
        publicKey: json["publicKey"],
      );

  Map<String, dynamic> toJson() => {
        "nonce": nonce,
        "publicKey": publicKey,
      };
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class TxType {
  // TxTypeCreateIdentity creates an ADI, which produces a synthetic chain
  // create transaction.
  static const CreateIdentity = 0x01;

  // TxTypeCreateTokenAccount creates an ADI token account, which produces a
  // synthetic chain create transaction.
  static const CreateTokenAccount = 0x02;

  // TxTypeSendTokens transfers tokens between token accounts, which produces
  // a synthetic deposit tokens transaction.
  static const SendTokens = 0x03;

  // TxTypeCreateDataAccount creates an ADI Data Account, which produces a
  // synthetic chain create transaction.
  static const CreateDataAccount = 0x04;

  // TxTypeWriteData writes data to an ADI Data Account, which *does not*
  // produce a synthetic transaction.
  static const WriteData = 0x05;

  // TxTypeWriteDataTo writes data to a Lite Data Account, which produces a
  // synthetic write data transaction.
  static const WriteDataTo = 0x06;

  // TxTypeAcmeFaucet produces a synthetic deposit tokens transaction that
  // deposits ACME tokens into a lite account.
  static const AcmeFaucet = 0x07;

  // TxTypeCreateToken creates a token issuer, which produces a synthetic
  // chain create transaction.
  static const CreateToken = 0x08;

  // TxTypeIssueTokens issues tokens to a token account, which produces a
  // synthetic token deposit transaction.
  static const IssueTokens = 0x09;

  // TxTypeBurnTokens burns tokens from a token account, which produces a
  // synthetic burn tokens transaction.
  static const BurnTokens = 0x0a;

  // TxTypeCreateKeyPage creates a key page, which produces a synthetic chain
  // create transaction.
  static const CreateKeyPage = 0x0c;

  // TxTypeCreateKeyBook creates a key book, which produces a synthetic chain
  // create transaction.
  static const CreateKeyBook = 0x0d;

  // TxTypeAddCredits converts ACME tokens to credits, which produces a
  // synthetic deposit credits transaction.
  static const AddCredits = 0x0e;

  // TxTypeUpdateKeyPage adds, removes, or updates keys in a key page, which
  // *does not* produce a synthetic transaction.
  static const UpdateKeyPage = 0x0f;
}

// type TokenTx struct {
//   Hash types.Bytes32    `json:"hash,omitempty" form:"hash" query:"hash" validate:"required"`
//   From types.UrlChain   `json:"from" form:"from" query:"from" validate:"required"`
//   To   []*TokenTxOutput `json:"to" form:"to" query:"to" validate:"required"`
//   Meta json.RawMessage  `json:"meta,omitempty" form:"meta" query:"meta" validate:"required"`
// }
class TokenTx {
  String hash;
  String urlChain;
  List<ApiRequestTxToDataTo> to;
  String meta;

  // usually a sender

  // factory TokenTx.fromRawJson(String str) => Signer.fromJson(json.decode(str));
  //
  // String toRawJson() => json.encode(toJson());
  //
  // factory TokenTx.fromJson(Map<String, dynamic> json) => Signer(
  //   url: json["url"],
  //   publicKey: json["publicKey"],
  // );
  //
  // Map<String, dynamic> toJson() => {
  //   "url": url,
  //   "publicKey": publicKey,
  // };
  //

  //
  //// MarshalBinary serialize the token transaction
// func (t *TokenTx) MarshalBinary() ([]byte, error) {
// 	var buffer bytes.Buffer
//
// 	buffer.Write(common.Uint64Bytes(types.TxTypeTokenTx.AsUint64()))
//
// 	data, err := t.From.MarshalBinary()
// 	if err != nil {
// 		return nil, fmt.Errorf("error marshaling From %s,%v", t.From, err)
// 	}
// 	buffer.Write(data)
//
// 	numOutputs := uint64(len(t.To))
// 	if numOutputs > MaxTokenTxOutputs {
// 		return nil, fmt.Errorf("too many outputs for token transaction, please specify between 1 and %d outputs", MaxTokenTxOutputs)
// 	}
// 	if numOutputs < 1 {
// 		return nil, fmt.Errorf("insufficient token transaction outputs, please specify between 1 and %d outputs", MaxTokenTxOutputs)
// 	}
// 	buffer.Write(common.Uint64Bytes(numOutputs))
// 	for i, v := range t.To {
// 		data, err = v.MarshalBinary()
// 		if err != nil {
// 			return nil, fmt.Errorf("error marshaling To[%d] %s,%v", i, v.URL, err)
// 		}
// 		buffer.Write(data)
// 	}
//
// 	a := types.Bytes(t.Meta)
// 	if a != nil {
// 		data, err = a.MarshalBinary()
// 		if err != nil {
// 			return nil, fmt.Errorf("error marshalling meta data, %v", err)
// 		}
// 		buffer.Write(data)
// 	}
//
// 	return buffer.Bytes(), nil
// }

  List<int> marshalBinary() {
    return [];
  }

  List<int> marshalBinarySendTokens(ApiRequestRawTx tx) {

    return [];
  }

// Generalized Marshal Binary
// func (s *Bytes) MarshalBinary() ([]byte, error) {
//   var buf [8]byte
//   l := s.Size(&buf)
//   i := l - len(*s)
//   data := make([]byte, l)
//   copy(data, buf[:i])
//   copy(data[i:], *s)
//   return data, nil
// }

}
