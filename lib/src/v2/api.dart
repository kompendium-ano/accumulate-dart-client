import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate/src/constants/globals.dart';
import 'package:accumulate/src/model/native/address.dart';
import 'package:accumulate/src/model/native/adi.dart';
import 'package:accumulate/src/model/native/keys/key.dart' as acme;
import 'package:accumulate/src/model/native/keys/keybook.dart';
import 'package:accumulate/src/model/native/keys/keypage.dart';
import 'package:accumulate/src/model/native/tx.dart';
import 'package:accumulate/src/network/client/accumulate/data_resp.dart';
import 'package:accumulate/src/network/client/accumulate/requests/adi/api_request_adi.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_credit.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_keybook.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_keypage.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_mask.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_metrics.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_token_account.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_tx_gen.dart';
import 'package:accumulate/src/network/client/accumulate/requests/api_request_tx_to.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_tx_to.dart' as txToV2;
import 'package:accumulate/src/network/client/accumulate/responses/resp_token_get.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_url.dart';
import 'package:accumulate/src/network/client/accumulate/v2/requests/api_request_url_pagination.dart';
import 'package:accumulate/src/network/client/json_rpc.dart';
import 'package:accumulate/src/utils/format.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

class ACMIApiV2 {
  String apiRPCUrl =
      "https://testnet.accumulatenetwork.io"; // "http://0.yellowstone.devnet.accumulatenetwork.io:33001";
  String apiPrefix = "/v2";

  Future<String> callGetVersion() async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";
    // ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("version", []); //[apiRequestUrl]);
    res.result;

    String ver = "";
    if (res.result != null) {
      ver = res.result["data"]["version"];
    }

    return ver;
  }

  Future<void> callGetMetrics(String type, String timeframe) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";
    ApiRequestMetrics apiRequestMetrics = new ApiRequestMetrics(type, timeframe);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("metrics", [apiRequestMetrics]);
    res.result;
  }

  // "faucet":  m.Faucet,
  Future<String> callFaucet(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase());
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("faucet", [apiRequestUrl]);
    res.result;

    String txid = "";
    if (res != null) {
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
    }

    return txid;
  }

  // RPC: "query" - query data
  Future<Data> callQuery(String path) async {
    String ACMEApiUrl = apiRPCUrl + "/v2";

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query", [apiRequestUrl]);
    res.result;

    Data urlData = new Data();
    if (res != null) {
      String accountType = res.result["type"];
      var mrState = res.result["merkleState"];
      int nonce = mrState["count"];
      urlData.nonce = nonce;

      LinkedHashMap dt = res.result["data"];
      if(accountType != "keyBook" && accountType != "tokenAccount") {
        if (dt.length > 2) {
          // process keypage
          String url = res.result["data"]["url"];
          String tokenUrl = res.result["data"]["tokenUrl"];
          String balance = res.result["data"]["balance"];
          int txcount = res.result["data"]["txCount"];
          int creditBalance = res.result["data"]["creditBalance"] ?? "0";

          urlData.url = url;
          urlData.tokenUrl = tokenUrl;
          if (balance != null) {
            urlData.balance = int.parse(balance);
          } else {
            urlData.balance = 0;
          }
          urlData.txcount = txcount;
          urlData.creditBalance = creditBalance;
        }
      }
    }
    return urlData;
  }

  // "query-directory":  m.QueryDirectory,
  Future<Data> callQueryDirectory(String path) async {
    String ACMEApiUrl = apiRPCUrl + "/v2";

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query-directory", [apiRequestUrl]);
    res.result;

    Data urlData = new Data();
    if (res != null) {
      String accountType = res.result["type"];
      var mrState = res.result["merkleState"];
      LinkedHashMap dt = res.result["data"];
      if (dt.length > 2) {
        String url = res.result["data"]["url"];
        String tokenUrl = res.result["data"]["tokenUrl"];
        String balance = res.result["data"]["balance"];
        int txcount = res.result["data"]["txCount"];
        int nonce = mrState["count"]; //res.result["data"]["nonce"];
        int creditBalance = res.result["data"]["creditBalance"] ?? "0";

        urlData.url = url;
        urlData.tokenUrl = tokenUrl;
        if (balance != null) {
          urlData.balance = int.parse(balance);
        } else {
          urlData.balance = 0;
        }
        urlData.txcount = txcount;
        urlData.nonce = nonce;
        urlData.creditBalance = creditBalance;
      }
    }
    return urlData;
  }

  // "query-chain":      m.QueryChain,

  // "query-tx":         m.QueryTx,

  // "query-data":       m.QueryData,

  // "query-data-set":   m.QueryDataSet,

  // "query-key-index":  m.QueryKeyPageIndex,

  // "create-data-account":  m.ExecuteWith(func() PL { return new(protocol.CreateDataAccount) }),

  //
  // RPC: "query-tx-history" (in v1 - "token-account-history")
  // Response:
  Future<List<Transaction>> callGetTokenTransactionHistory(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";

    ApiRequestUrWithPagination apiRequestUrlWithPagination =
        new ApiRequestUrWithPagination(currAddr.address.toLowerCase(), 1, 100);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("query-tx-history", [apiRequestUrlWithPagination]);
    res.result;

    // Collect transaction iteratively
    List<Transaction> txs = [];
    if (res != null) {
      var data = res.result["data"];
      String type = res.result["type"];

      for (var i = 0; i < data.length; i++) {
        var tx = data[i];

        var internalData = tx["data"];
        String txid = internalData["txid"];

        // if nothing that was a faucet
        Transaction txl = new Transaction("", "", txid, "", "", 0, "");
        txs.add(txl);
      }
    }

    return txs;
  }

  // "create-adi":           m.ExecuteWith(func() PL { return new(protocol.IdentityCreate) }),
  Future<String> callCreateAdi(Address currAddr, IdentityADI adiToCreate, int timestamp,
      [String keybookName, String keypageName]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";

    // check if keybooknameavailable
    ApiRequestADI data = new ApiRequestADI(adiToCreate.path, currAddr.puk, "", "");

    SignatureInfo signatureInfo =
        SignatureInfo(url: currAddr.address, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: currAddr.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: 1, index: 0);
    txToV2.ApiRequestRawTx_ADI tx = txToV2.ApiRequestRawTx_ADI(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: currAddr.address,
        origin: currAddr.address,
        keyPage: keyPage);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareTransactionAdi(tx);
    List<int> dataBinary = prep.dataPayload;

    //TokenTx tokenTx = new TokenTx();
    //List<int> dataBinary = tokenTx.marshal(); // In Go: tokentx.MarshalBinary()

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen(null, signatureInfo);
    txGen.transaction = dataBinary;

    List<int> txhashGenRemote = prep.txHash;
    List<int> txhashGenLocal = txGen.generateTransactionHash();
    List<int> txhashGen = txhashGenRemote; //txhashGenLocal;
    txGen.hash = txhashGenRemote;

    // Check if siginfo equal
    bool isWorkflowProcessTheSame = false;
    if (listEquals(prep.signInfoMarshaled, signInfoMarshaled)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame) print('same tx hashes');

    // Check if generated hashes are equal
    bool isWorkflowProcessTheSame2 = false;
    if (listEquals(txhashGenRemote, txhashGenLocal)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame2) print('same tx hashes');

    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message whic is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.signature = sigRem; // update underlying structure

    txToV2.ApiRequestRaw_ADI apiRequestSendTo = txToV2.ApiRequestRaw_ADI(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-adi", [apiRequestSendTo]);
    res.result;

    String txid = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
      String hash = res.result["data"]["hash"];
      String code = res.result["data"]["code"];
      String mempool = res.result["data"]["mempool"];
      String codespace = res.result["data"]["codespace"];
    }

    return txid;
  }

  // "create-key-book":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyBook) }),
  Future<Tuple2<String, String>> callKeyBookCreate(
      IdentityADI sponsorADI, KeyBook keybook, List<String> pages, int timestamp) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";

    ApiRequestKeyBook data = new ApiRequestKeyBook(keybook.path, pages);

    SignatureInfo signatureInfo =
        SignatureInfo(url: keybook.path, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: sponsorADI.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: 1, index: 0);

    ApiRequestRawTx_KeyBook tx =
        ApiRequestRawTx_KeyBook(data: data, signer: signer, sig: "", sponsor: sponsorADI.path, keyPage: keyPage);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareKeyBook(tx);
    List<int> dataBinary = prep.dataPayload;

    //TokenTx tokenTx = new TokenTx();
    //List<int> dataBinary = tokenTx.marshal(); // In Go: tokentx.MarshalBinary()

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen(null, signatureInfo);
    txGen.transaction = dataBinary;

    List<int> txhashGenRemote = prep.txHash;
    List<int> txhashGenLocal = txGen.generateTransactionHash();
    List<int> txhashGen = txhashGenRemote; //txhashGenLocal;
    txGen.hash = txhashGenRemote;

    // Check if siginfo equal
    bool isWorkflowProcessTheSame = false;
    if (listEquals(prep.signInfoMarshaled, signInfoMarshaled)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame) print('same tx hashes');

    // Check if generated hashes are equal
    bool isWorkflowProcessTheSame2 = false;
    if (listEquals(txhashGenRemote, txhashGenLocal)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame2) print('same tx hashes');

    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message whic is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.sig = sigRem; // update underlying structure

    ApiRequestRaw_KeyBook apiRequestSendTo = ApiRequestRaw_KeyBook(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-key-book", [apiRequestSendTo]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      debugPrint(res.result.toString());

      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
      hash = res.result["data"]["hash"];
      String code = res.result["data"]["code"];
      String mempool = res.result["data"]["mempool"];
      String codespace = res.result["data"]["codespace"];
    }

    return Tuple2<String, String>(txid, hash);
  }

  // "create-key-page":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyPage) }),
  Future<Tuple2<String, String>> callKeyPageCreate(
      IdentityADI sponsorADI, KeyPage keypage, List<String> keys, int timestamp) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";

    var keysParam = keys.map((e) => KeySpecParams(e)).toList();
    ApiRequestKeyPage data = new ApiRequestKeyPage(keypage.path, keysParam);

    SignatureInfo signatureInfo =
        SignatureInfo(url: keypage.path, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: sponsorADI.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: 1, index: 0);

    ApiRequestRawTx_KeyPage tx = ApiRequestRawTx_KeyPage(
        data: data, signer: signer, sig: "", sponsor: sponsorADI.path, keypageInfo: keyPageInfo);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareKeyPage(tx);
    List<int> dataBinary = prep.dataPayload;

    //TokenTx tokenTx = new TokenTx();
    //List<int> dataBinary = tokenTx.marshal(); // In Go: tokentx.MarshalBinary()

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen(null, signatureInfo);
    txGen.transaction = dataBinary;

    List<int> txhashGenRemote = prep.txHash;
    List<int> txhashGenLocal = txGen.generateTransactionHash();
    List<int> txhashGen = txhashGenRemote; //txhashGenLocal;
    txGen.hash = txhashGenRemote;

    // Check if siginfo equal
    bool isWorkflowProcessTheSame = false;
    if (listEquals(prep.signInfoMarshaled, signInfoMarshaled)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame) print('same tx hashes');

    // Check if generated hashes are equal
    bool isWorkflowProcessTheSame2 = false;
    if (listEquals(txhashGenRemote, txhashGenLocal)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame2) print('same tx hashes');

    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.sig = sigRem; // update underlying structure

    ApiRequestRaw_KeyPage apiRequestSendTo = ApiRequestRaw_KeyPage(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-key-page", [apiRequestSendTo]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
      hash = res.result["data"]["hash"];
      String code = res.result["data"]["code"];
      String mempool = res.result["data"]["mempool"];
      String codespace = res.result["data"]["codespace"];
    }

    return Tuple2(txid, hash);
  }

  // "create-token":         m.ExecuteWith(func() PL { return new(protocol.CreateToken) }),
  // "create-token-account": m.ExecuteWith(func() PL { return new(protocol.TokenAccountCreate) }),
  // "send-tokens":          m.ExecuteWith(func() PL { return new(api.SendTokens) }, "From", "To"),
  // "add-credits":          m.ExecuteWith(func() PL { return new(protocol.AddCredits) }),
  // "update-key-page":      m.ExecuteWith(func() PL { return new(protocol.UpdateKeyPage) }),
  // "write-data":           m.ExecuteWith(func() PL { return new(protocol.WriteData) }),

  ///////////////////////////////////////////////////////////////////////////////////////
  Future<DataResp> callPrepareKeyBook(ApiRequestRawTx_KeyBook tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://178.20.158.25:56660/v1";
    ApiRequestRaw_KeyBook apiRequestSendTo = ApiRequestRaw_KeyBook(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("keybook-create-prepare", [apiRequestSendTo]);
      res.result;
    } catch (e) {
      e.toString();
    }

    String payload = "";
    String sigInfoMarsh = "";
    String txhashRem = "";
    String nHashRem = "";
    if (res != null) {
      //payload = res.result;
      payload = res.result["data"]["payload"];
      sigInfoMarsh = res.result["data"]["ss"];
      txhashRem = res.result["data"]["txhash"];
      nHashRem = res.result["data"]["nhash"];
    }
    //return payload;

    List<String> vals = payload.substring(1, payload.length - 1).split(' ');
    List<int> valuesInt = vals.map((e) => int.parse(e)).toList();

    List<String> valsSigInfo = sigInfoMarsh.substring(1, sigInfoMarsh.length - 1).split(' ');
    List<int> valuesIntSigInfo = valsSigInfo.map((e) => int.parse(e)).toList();

    List<String> valsTxHash = txhashRem.substring(1, txhashRem.length - 1).split(' ');
    List<int> valuesIntTxHash = valsTxHash.map((e) => int.parse(e)).toList();

    List<String> valsNHash = nHashRem.substring(1, nHashRem.length - 1).split(' ');
    List<int> valuesIntNHash = valsNHash.map((e) => int.parse(e)).toList();

    return DataResp(valuesInt, valuesIntSigInfo, valuesIntTxHash, valuesIntNHash);
  }

  Future<DataResp> callPrepareKeyPage(ApiRequestRawTx_KeyPage tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://178.20.158.25:56660/v2";
    ApiRequestRaw_KeyPage apiRequestSendTo = ApiRequestRaw_KeyPage(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("keypage-create-prepare", [apiRequestSendTo]);
      res.result;
    } catch (e) {
      e.toString();
    }

    String payload = "";
    String sigInfoMarsh = "";
    String txhashRem = "";
    String nHashRem = "";
    if (res != null) {
      //payload = res.result;
      payload = res.result["data"]["payload"];
      sigInfoMarsh = res.result["data"]["ss"];
      txhashRem = res.result["data"]["txhash"];
      nHashRem = res.result["data"]["nhash"];
    }
    //return payload;F

    List<String> vals = payload.substring(1, payload.length - 1).split(' ');
    List<int> valuesInt = vals.map((e) => int.parse(e)).toList();

    List<String> valsSigInfo = sigInfoMarsh.substring(1, sigInfoMarsh.length - 1).split(' ');
    List<int> valuesIntSigInfo = valsSigInfo.map((e) => int.parse(e)).toList();

    List<String> valsTxHash = txhashRem.substring(1, txhashRem.length - 1).split(' ');
    List<int> valuesIntTxHash = valsTxHash.map((e) => int.parse(e)).toList();

    List<String> valsNHash = nHashRem.substring(1, nHashRem.length - 1).split(' ');
    List<int> valuesIntNHash = valsNHash.map((e) => int.parse(e)).toList();

    return DataResp(valuesInt, valuesIntSigInfo, valuesIntTxHash, valuesIntNHash);

    //return valuesInt;
  }

  Future<DataResp> callPrepareTransactionAdi(txToV2.ApiRequestRawTx_ADI tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.signature = sig; // dummy sig

    String ACMEApiUrl = "http://178.20.158.25:56660/v2";
    txToV2.ApiRequestRaw_ADI apiRequestSendTo = txToV2.ApiRequestRaw_ADI(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("adi-create-prepare", [apiRequestSendTo]);
      res.result;
    } catch (e) {
      e.toString();
    }

    String payload = "";
    String sigInfoMarsh = "";
    String txhashRem = "";
    String nHashRem = "";
    if (res != null) {
      //payload = res.result;
      payload = res.result["data"]["payload"];
      sigInfoMarsh = res.result["data"]["ss"];
      txhashRem = res.result["data"]["txhash"];
      nHashRem = res.result["data"]["nhash"];
    }
    //return payload;

    List<String> vals = payload.substring(1, payload.length - 1).split(' ');
    List<int> valuesInt = vals.map((e) => int.parse(e)).toList();

    List<String> valsSigInfo = sigInfoMarsh.substring(1, sigInfoMarsh.length - 1).split(' ');
    List<int> valuesIntSigInfo = valsSigInfo.map((e) => int.parse(e)).toList();

    List<String> valsTxHash = txhashRem.substring(1, txhashRem.length - 1).split(' ');
    List<int> valuesIntTxHash = valsTxHash.map((e) => int.parse(e)).toList();

    List<String> valsNHash = nHashRem.substring(1, nHashRem.length - 1).split(' ');
    List<int> valuesIntNHash = valsNHash.map((e) => int.parse(e)).toList();

    return DataResp(valuesInt, valuesIntSigInfo, valuesIntTxHash, valuesIntNHash);

    //return valuesInt;
  }

  Future<String> callAddCredits(Address currAddr, int amount, int timestamp,
      [KeyPage currKeyPage, acme.Key currKey]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v2";

    // Because we can send to accounts and keybooks ath the same time
    ApiRequestCredits data;
    if (currKeyPage != null) {
      data = new ApiRequestCredits(currKeyPage.path.toLowerCase(), amount, false);
    } else {
      data = new ApiRequestCredits(currAddr.address.toLowerCase(), amount, false);
    }

    SignatureInfo signatureInfo =
    SignatureInfo(url: currAddr.address.toLowerCase(), msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    String puk;
    if (currKeyPage != null) {
      if (currKey != null) {
        puk = currKey.puk;
        publicKey = ed.PublicKey(HEX.decode(currKey.puk));
        privateKey = ed.PrivateKey(HEX.decode(currKey.pikHex));
      }
    } else {
      puk = currAddr.puk;
      publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
      privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
      var keyPair = ed.KeyPair(privateKey, publicKey);
    }

    Signer signer = Signer(publicKey: puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: 1, index: 0);

    ApiRequestRawTx_Credits tx = ApiRequestRawTx_Credits(
        data: data, signer: signer, sig: "", sponsor: currAddr.address, keypageInfo: keyPageInfo);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareCredits(tx);
    List<int> dataBinary = prep.dataPayload;

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen(null, signatureInfo);
    txGen.transaction = dataBinary;

    List<int> txhashGenRemote = prep.txHash;
    List<int> txhashGenLocal = txGen.generateTransactionHash();
    List<int> txhashGen = txhashGenRemote; //txhashGenLocal;
    txGen.hash = txhashGenRemote;

    // Check if siginfo equal
    bool isWorkflowProcessTheSame = false;
    if (listEquals(prep.signInfoMarshaled, signInfoMarshaled)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame) print('same tx hashes');

    // Check if generated hashes are equal
    bool isWorkflowProcessTheSame2 = false;
    if (listEquals(txhashGenRemote, txhashGenLocal)) isWorkflowProcessTheSame = true;

    if (isWorkflowProcessTheSame2) print('same tx hashes');

    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.sig = sigRem; // update underlying structure

    ApiRequestRaw_Credits apiRequestSendTo = ApiRequestRaw_Credits(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("add-credits", [apiRequestSendTo]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
      hash = res.result["data"]["hash"];
      String code = res.result["data"]["code"];
      String mempool = res.result["data"]["mempool"];
      String codespace = res.result["data"]["codespace"];
    }
    return txid;
  }

  Future<DataResp> callPrepareCredits(ApiRequestRawTx_Credits tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://178.20.158.25:56660/v2";
    ApiRequestRaw_Credits apiRequestSendTo = ApiRequestRaw_Credits(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("credits-prepare", [apiRequestSendTo]);
      res.result;
    } catch (e) {
      e.toString();
    }

    String payload = "";
    String sigInfoMarsh = "";
    String txhashRem = "";
    String nHashRem = "";
    if (res != null) {
      //payload = res.result;
      payload = res.result["data"]["payload"];
      sigInfoMarsh = res.result["data"]["ss"];
      txhashRem = res.result["data"]["txhash"];
      nHashRem = res.result["data"]["nhash"];
    }

    List<String> vals = payload.substring(1, payload.length - 1).split(' ');
    List<int> valuesInt = vals.map((e) => int.parse(e)).toList();

    List<String> valsSigInfo = sigInfoMarsh.substring(1, sigInfoMarsh.length - 1).split(' ');
    List<int> valuesIntSigInfo = valsSigInfo.map((e) => int.parse(e)).toList();

    List<String> valsTxHash = txhashRem.substring(1, txhashRem.length - 1).split(' ');
    List<int> valuesIntTxHash = valsTxHash.map((e) => int.parse(e)).toList();

    List<String> valsNHash = nHashRem.substring(1, nHashRem.length - 1).split(' ');
    List<int> valuesIntNHash = valsNHash.map((e) => int.parse(e)).toList();

    return DataResp(valuesInt, valuesIntSigInfo, valuesIntTxHash, valuesIntNHash);

    //return valuesInt;
  }

}
