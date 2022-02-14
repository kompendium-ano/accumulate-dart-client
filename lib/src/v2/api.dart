import 'dart:collection';
import 'dart:typed_data';
import 'dart:developer';

import 'package:accumulate/src/json_rpc.dart';
import 'package:accumulate/src/model/address.dart';
import 'package:accumulate/src/model/adi.dart';
import 'package:accumulate/src/model/keys/keybook.dart';
import 'package:accumulate/src/model/keys/keypage.dart';
import 'package:accumulate/src/model/keys/key.dart' as acme;
import 'package:accumulate/src/model/tx.dart';
import 'package:accumulate/src/utils/marshaller.dart';
import 'package:accumulate/src/v2/requests/api_request_tx.dart';
import 'package:accumulate/src/v2/requests/api_request_url_pagination.dart';
import 'package:accumulate/src/v2/responses/resp_token_get.dart';
import 'package:accumulate/src/v2/requests/api_request_metrics.dart';
import 'package:accumulate/src/v2/requests/api_request_url.dart';
import 'package:accumulate/src/v2/requests/api_request_adi.dart' as V2;
import 'package:accumulate/src/v2/requests/api_request_keybook.dart';
import 'package:accumulate/src/v2/requests/api_request_keypage.dart';
import 'package:accumulate/src/v2/requests/api_request_keypage_update.dart';
import 'package:accumulate/src/v2/requests/api_request_token_account.dart' as V2;
import 'package:accumulate/src/v2/requests/api_request_tx_gen.dart';
import 'package:accumulate/src/v2/requests/api_request_credit.dart' as V2;
import 'package:accumulate/src/v2/requests/api_request_tx_to.dart' as V2;
import 'package:accumulate/src/v2/requests/api_request_tx_gen.dart' as V2;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';


class ACMEApiV2 {
  String apiRPCUrl = "https://testnet.accumulatenetwork.io/";
  String apiPrefix = "v2";

  ACMEApiV2(this.apiRPCUrl, this.apiPrefix );

  Future<String> callGetVersion() async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
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
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestMetrics apiRequestMetrics = new ApiRequestMetrics(type, timeframe);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("metrics", [apiRequestMetrics]);
    res.result;
  }

  // "faucet":  m.Faucet,
  Future<String> callFaucet(Address currAddr) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase());
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("faucet", [apiRequestUrl]);
    res.result;

    String txid = "";
    if (res != null) {
      txid = res.result["txid"];
      String envelopeHash = res.result["envelopeHash"];
    }

    return txid;
  }

  // RPC: "query" - query data
  Future<Data> callQuery(String path) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

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
      switch (accountType) {
        case "keyBook":
        case "tokenAccount":
          if (dt.length > 2) {
            // process keypage
            String url = res.result["data"]["url"];
            String tokenUrl = res.result["data"]["tokenUrl"];
            String balance = res.result["data"]["balance"];

            urlData.url = url;
            urlData.tokenUrl = tokenUrl;
            if (balance != null) {
              urlData.balance = int.parse(balance);
            } else {
              urlData.balance = 0;
            }
            urlData.txcount = 0;
            urlData.creditBalance = 0;
          }
          break;
        case "keyPage":
          if (dt.length > 2) {
            String url = res.result["data"]["url"];
            String creditBalance = res.result["data"]["creditBalance"] ?? "0";

            urlData.url = url;
            urlData.tokenUrl = res.result["chainId"]; // as network name
            urlData.creditBalance = int.parse(creditBalance);
          }
          break;
        case "liteTokenAccount":
          if (dt.length > 2) {
            String url = res.result["data"]["url"];
            String tokenUrl = res.result["data"]["tokenUrl"];
            String balance = res.result["data"]["balance"];
            int txcount = res.result["data"]["txCount"];
            int nonce = res.result["data"]["nonce"];
            String creditBalance = res.result["data"]["creditBalance"] ?? "0";

            urlData.url = url;
            urlData.tokenUrl = tokenUrl;
            urlData.balance = int.parse(balance);
            urlData.txcount = txcount;
            urlData.nonce = nonce;
            urlData.creditBalance = int.parse(creditBalance);
          }
          break;
      }
    }
    return urlData;
  }

  // "query-directory":  m.QueryDirectory,
  Future<DataDirectory> callQueryDirectory(String path) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query-directory", [apiRequestUrl]);
    res.result;

    DataDirectory directoryData = new DataDirectory();
    directoryData.keybooksCount = 1;
    if (res != null) {
      String accountType = res.result["type"];
      int total = res.result["total"];
      //List<String> entries = res.result["data"]["entries"].cast<String>();
      //directoryData.entities = entries;
      // entries.length > 2
      if (total > 2) {
        directoryData.tokenAccountsCount = total - 2;
      }
    }

    return directoryData;
  }

  // "query-chain":      m.QueryChain,

  // "query-tx":         m.QueryTx,
  // RPC: "token-tx"
  Future<Transaction> callGetTokenTransaction(String txhash) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestTx apiRequestHash = ApiRequestTx(txhash);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("query-tx", [apiRequestHash]);
    res.result;

    Transaction tx;
    if (res != null) {
      var data = res.result["data"];
      String type = res.result["type"];

      switch (type) {
        case "syntheticTokenDeposit":
          String txid = res.result["data"]["txid"];
          String from = res.result["data"]["from"];
          String to = res.result["data"]["to"];
          int amount = int.parse(res.result["data"]["amount"]);
          String tokenUrl = res.result["data"]["tokenUrl"];

          tx = new Transaction(type, "", txid, from, to, amount, tokenUrl);
          break;
        case "createKeyPage":
          String txid = res.result["txid"];
          String from = res.result["origin"];
          String to = res.result["data"]["url"];
          LinkedHashMap sigs = res.result["signatures"][0];
          int dateNonce = sigs["nonce"];

          tx = new Transaction(type, "", txid, from, to, 0, "ACME");
          tx.created = dateNonce;

          break;
        case "acmeFaucet":
          String txid = res.result["data"]["txid"];
          String from = res.result["data"]["from"];
          String to = res.result["data"]["url"];
          int amount = 1000000000;
          LinkedHashMap sigs = res.result["signatures"][0];
          int dateNonce = sigs["Nonce"];

          tx = new Transaction(type, "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;

          break;
        default:
          String txid = res.result["data"]["txid"];
          String from = res.result["data"]["from"];
          //ApiRespTxTo to = res.result["data"]["to"];
          LinkedHashMap dataTo = res.result["data"]["to"][0];
          String to = dataTo["url"];
          int amount = dataTo["amount"];
          //int amount = int.parse(res.result["data"]["amount"]);
          //String tokenUrl = res.result["data"]["tokenUrl"];

          int dateNonce = res.result["signer"]["nonce"];

          tx = new Transaction(type, "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;
      }
    }

    return tx;
  }

// "query-data":       m.QueryData,

// "query-data-set":   m.QueryDataSet,

// "query-key-index":  m.QueryKeyPageIndex,

// "create-data-account":  m.ExecuteWith(func() PL { return new(protocol.CreateDataAccount) }),

// RPC: "query-tx-history" (in v1 - "token-account-history")
  Future<List<Transaction>> callGetTokenTransactionHistory(Address currAddr) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

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
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    //timestamp = timestamp * 1000;

    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    // TODO: check if keybook name available
    // TODO: allow newly generated keypair

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    V2.Signer signer = V2.Signer(publicKey: currAddr.puk, nonce: timestamp);
    V2.ApiRequestRawTxKeyPage keyPage = V2.ApiRequestRawTxKeyPage(height: 1); //, index: 0);

    // prepare data
    V2.ApiRequestADI data = V2.ApiRequestADI(adiToCreate.path, currAddr.puk, keybookName ?? "", keypageName ?? "");

    V2.ApiRequestRawTx_ADI tx = V2.ApiRequestRawTx_ADI(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: currAddr.address,
        origin: currAddr.address,
        keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: currAddr.address,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);
    List<int> dataBinary = tokenTx.marshalBinaryCreateIdentity(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + txHash
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig; // update underlying structure

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-adi", [tx]);
    res.result;

    String txid = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      print('Response: $message');
      if (code == 12) {}
    }

    return txid;
  }

// RPC: "token-account" - Create token account
  Future<String> callCreateTokenAccount(
      Address currAddr, IdentityADI sponsorADI, String tokenAccountName, String keybookPath, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    timestamp = timestamp * 1000;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String signerKey = currAddr.puk;
    String sponsorPath = currAddr.address; //sponsorADI.path;

    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;
    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    V2.Signer signer = V2.Signer(publicKey: signerKey, nonce: timestamp);
    V2.ApiRequestRawTxKeyPage keyPage =
        V2.ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: keyPageIndexInsideKeyBook); //, index: 0);

    V2.ApiRequestTokenAccount data =
        V2.ApiRequestTokenAccount(sponsorADI.path + "/" + tokenAccountName, "acc://acme", keybookPath, false);

    V2.ApiRequestRawTx_TokenAccount tx = V2.ApiRequestRawTx_TokenAccount(
        payload: data, signer: signer, origin: sponsorPath, signature: "", sponsor: sponsorPath, keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorPath,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);
    List<int> dataBinary = tokenTx.marshalBinaryCreateTokenAccount(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + txHash
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig; // update underlying structure

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-token-account", [tx]);
    res.result;

    String txid = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log("API RESULT: ${txid}");
      log("API RESULT: ${message}");
      if (code == 12) {}
    }

    return txid;
  }

// "create-key-book":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyBook) }),
  Future<Tuple2<String, String>> callKeyBookCreate(
      IdentityADI sponsorADI, KeyBook keybook, List<String> pages, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight, String keybookPath]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    timestamp = timestamp * 1000;
    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String signerKey = sponsorADI.puk;
    String sponsorPath = sponsorADI.path;

    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));

      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    V2.Signer signer = V2.Signer(publicKey: signerKey, nonce: timestamp);

    V2.ApiRequestRawTxKeyPage keyPage = V2.ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook ?? 0); // 1,0 - for defaults

    ApiRequestKeyBook data = new ApiRequestKeyBook(keybook.path, pages);

    V2.ApiRequestRawTx_KeyBook tx = V2.ApiRequestRawTx_KeyBook(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorADI.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);
    List<int> dataBinary = tokenTx.marshalBinaryCreateKeyBook(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + transaction hash generated
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig;

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-key-book", [tx]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log('Response: $message');
      if (code == 12) {}
    }

    return Tuple2(txid, hash);
  }

// "create-key-page":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyPage) }),
  Future<Tuple2<String, String>> callKeyPageCreate(
      IdentityADI sponsorADI, KeyPage keypage, List<String> keys, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight, String keybookPath]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    timestamp = timestamp * 1000;
    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String signerKey = sponsorADI.puk;
    String sponsorPath = sponsorADI.path;

    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));

      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    V2.Signer signer = V2.Signer(publicKey: signerKey, nonce: timestamp);

    V2.ApiRequestRawTxKeyPage keyPage = V2.ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook ?? 0); // 1,0 - for defaults

    //prepare payload data
    var keypageKeys = keys.map((e) => KeySpecParams(e)).toList();
    ApiRequestKeyPage data = new ApiRequestKeyPage(keypage.path, keypageKeys);

    V2.ApiRequestRawTx_KeyPage tx = V2.ApiRequestRawTx_KeyPage(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorADI.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);

    List<int> dataBinary = tokenTx.marshalBinaryCreateKeyPage(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + transaction hash generated
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig; // update underlying structure

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-key-page", [tx]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log('Response: $message');
      if (code == 12) {}
    }

    return Tuple2(txid, hash);
  }

// "update-key-page":      m.ExecuteWith(func() PL { return new(protocol.UpdateKeyPage) })
  Future<Tuple2<String, String>> callKeyPageUpdate(KeyPage keypage, String operationName, String keyPuk, String keyPik,
      String newKeyPuk, int timestamp, int keyPageHeight) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    timestamp = timestamp * 1000;
    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(keyPuk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(keyPik));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String signerKey = keyPuk;
    String sponsorPath = keypage.path;

    if (keyPuk != null) {
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = keypage.path;
      ;
    }

    V2.Signer signer = V2.Signer(publicKey: signerKey, nonce: timestamp);

    V2.ApiRequestRawTxKeyPage keyPage = V2.ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook ?? 0); // 1,0 - for defaults

    //prepare payload data
    ApiRequestKeyPageUpdate data = ApiRequestKeyPageUpdate(operationName, keyPuk, newKeyPuk, keypage.path);

    V2.ApiRequestRawTx_KeyPageUpdate tx = V2.ApiRequestRawTx_KeyPageUpdate(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: keypage.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);
    List<int> dataBinary = tokenTx.marshalBinaryKeyPageUpdate(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + transaction hash generated
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig;

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("update-key-page", [tx]);
    res.result;

    String txid = "";
    String hash = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log('Response: $message');
      if (code == 12) {}
    }

    return Tuple2(txid, hash);
  }

// "send-tokens":          m.ExecuteWith(func() PL { return new(api.SendTokens) }, "From", "To"),
  Future<String> callCreateTokenTransaction(Address addrFrom, Address addrTo, String amount, int timestamp,
      [acme.Key providedKey, int providedKeyPageChainHeight, int keyPageIndexInsideKeyBook]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    timestamp = timestamp * 1000;

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    var pukToUse;
    int keypageHeightToUse = 1;

    if (providedKey == null) {
      // use keys from account
      pukToUse = addrFrom.puk;
      publicKey = ed.PublicKey(HEX.decode(addrFrom.puk));
      privateKey = ed.PrivateKey(HEX.decode(addrFrom.pikHex));
      var keyPair = ed.KeyPair(privateKey, publicKey);
    } else {
      // use provided keys values
      pukToUse = providedKey.puk;
      publicKey = ed.PublicKey(HEX.decode(providedKey.puk));
      privateKey = ed.PrivateKey(HEX.decode(providedKey.pikHex));
      var keyPair = ed.KeyPair(privateKey, publicKey);
      keypageHeightToUse = providedKeyPageChainHeight;
    }

    //prepare data
    int amountToDeposit = (double.parse(amount) * 100000000).round().toInt(); // assume 8 decimal places
    V2.ApiRequestTxToDataTo to = V2.ApiRequestTxToDataTo(url: addrTo.address, amount: amountToDeposit);
    V2.ApiRequestTxToData data =
        V2.ApiRequestTxToData(to: [to], hash: "0000000000000000000000000000000000000000000000000000000000000000");

    V2.Signer signer = V2.Signer(publicKey: pukToUse, nonce: timestamp);

    V2.ApiRequestRawTxKeyPage keyPage = V2.ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook ?? 0); // 1,0 - for defaults

    V2.ApiRequestRawTx tx = V2.ApiRequestRawTx(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: addrFrom.address,
        origin: addrFrom.address,
        keyPage: keyPage);

    V2.TokenTx tokenTx = V2.TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: addrFrom.address,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook ?? 0);
    List<int> dataBinary = tokenTx.marshalBinarySendTokens(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + transaction hash generated
    Uint8List signature = ed.sign(privateKey, msgToSign);

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);

    tx.signature = sig; // update underlying structure

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("send-tokens", [tx]);
    res.result;

    String txid = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log('Response: $message');
      if (code == 12) {}
    }

    return txid;
  }

// "add-credits":          m.ExecuteWith(func() PL { return new(protocol.AddCredits) }),
  Future<String> callAddCredits(Address currAddr, int amount, int timestamp,
      [KeyPage currKeyPage, acme.Key currKey]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    //timestamp = timestamp * 1000;
    int keypageHeightToUse = 1;
    String currOrigin;

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    String puk = currAddr.puk;
    // if (currKeyPage != null) {
    //   if (currKey != null) {
    //     puk = currKey.puk;
    //     publicKey = ed.PublicKey(HEX.decode(currKey.puk));
    //     privateKey = ed.PrivateKey(HEX.decode(currKey.pikHex));
    //   }
    // } else {
    //   puk = currAddr.puk;
    //   publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    //   privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    //   var keyPair = ed.KeyPair(privateKey, publicKey);
    // }

    //////////////////
    // NB: temp, only lite to lite, lite to kp supported, override key
    //     as origin and sponsor always Lite Account for now
    puk = currAddr.puk;
    publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    ///////////////

    // Because we can send to accounts and keybooks ath the same time
    V2.ApiRequestCredits data;
    if (currKeyPage != null) {
      data = V2.ApiRequestCredits(currKeyPage.path, amount);
      currOrigin = currAddr.address;
    } else {
      data = V2.ApiRequestCredits(currAddr.address.toLowerCase(), amount);
      currOrigin = currAddr.address;
    }

    V2.Signer signer = V2.Signer(publicKey: puk, nonce: timestamp);
    V2.ApiRequestRawTxKeyPage keyPageInfo = V2.ApiRequestRawTxKeyPage(height: 1, index: 0);

    V2.ApiRequestRawTx_Credits tx = V2.ApiRequestRawTx_Credits(
        payload: data,
        signer: signer,
        signature: "",
        origin: currAddr.address,
        sponsor: currAddr.address,
        keyPage: keyPageInfo);

    V2.TokenTx tokenTx = V2.TokenTx();
    V2.TransactionHeader header = V2.TransactionHeader(
        origin: currAddr.address, nonce: timestamp, keyPageHeight: keypageHeightToUse, keyPageIndex: 0);
    List<int> dataBinary = tokenTx.marshalBinaryAddCredits(tx);

    // Generalized version of GenTransaction in Go
    V2.ApiRequestTxGen txGen = V2.ApiRequestTxGen([], header, dataBinary);
    txGen.hash = txGen.generateTransactionHash();

    // message is (timestamp/nonce) + hash
    List<int> msg = [];
    msg.addAll(uint64ToBytesNonce(timestamp)); // VLQ converted timestamp
    msg.addAll(txGen.hash);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce) + txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated

    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    sig = HEX.encode(signature);
    tx.signature = sig; // update underlying structure

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("add-credits", [tx]);
    res.result;

    String txid = "";
    if (res != null) {
      String type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String simpleHash = res.result["simpleHash"];
      String transactionHash = res.result["transactionHash"];
      String envelopeHash = res.result["envelopeHash"];
      String hash = res.result["hash"];
      int code = res.result["code"];
      String message = res.result["message"];

      log('Response: $message');
    }
    return txid;
  }
}
