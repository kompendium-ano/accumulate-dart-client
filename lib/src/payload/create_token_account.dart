import "dart:typed_data";
import '../utils.dart';

import "../acc_url.dart";
import "../encoding.dart";
import "../tx_types.dart";
import "base_payload.dart";
import '../receipt.dart';
import 'create_token.dart';

class CreateTokenAccountParam {
  dynamic url;
  dynamic tokenUrl;
  List<AccURL>? authorities;
  TokenIssuerProofParam? proof;
  String? memo;
  Uint8List? metadata;
}

class TokenIssuerProofParam {
  dynamic transaction;
  late Receipt receipt;

}

class CreateTokenAccount extends BasePayload {
  late AccURL _url;
  late AccURL _tokenUrl;
  List<AccURL>? _authorities;
  TokenIssuerProofParam? _proof;

  CreateTokenAccount(CreateTokenAccountParam createTokenAccountParam)
      : super() {
    _url = AccURL.toAccURL(createTokenAccountParam.url);
    _tokenUrl = AccURL.toAccURL(createTokenAccountParam.tokenUrl);
    _authorities = createTokenAccountParam.authorities;
    _proof = createTokenAccountParam.proof;
    super.memo = createTokenAccountParam.memo;
    super.metadata = createTokenAccountParam.metadata;
  }

  @override
  Uint8List extendedMarshalBinary() {
    List<int> forConcat = [];

    forConcat
        .addAll(uvarintMarshalBinary(TransactionType.createTokenAccount, 1));
    forConcat.addAll(stringMarshalBinary(_url.toString(), 2));
    forConcat.addAll(stringMarshalBinary(_tokenUrl.toString(), 3));



    if (_authorities != null) {
      for (AccURL accURL in _authorities!) {
        forConcat.addAll(stringMarshalBinary(accURL.toString(), 7));
      }
    }

    if (_proof != null) {
      forConcat.addAll(bytesMarshalBinary(_marshalBinaryProof(_proof!), 8));
    }

    return forConcat.asUint8List();
  }

  Uint8List _marshalBinaryProof(TokenIssuerProofParam proof){
    List<int>  forConcat = [];

  final txMarshalBinary =
      proof.transaction is CreateToken
  ? proof.transaction.marshalBinary()
      : CreateToken(proof.transaction).marshalBinary();

  forConcat.addAll(bytesMarshalBinary(txMarshalBinary, 1));
  forConcat.addAll(bytesMarshalBinary(Receipt.marshalBinaryReceipt(proof.receipt), 2));

    return forConcat.asUint8List();
}

}
