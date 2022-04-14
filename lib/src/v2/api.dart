import 'dart:collection';
import 'dart:developer';
import 'dart:typed_data';

import 'package:accumulate_api/src/json_rpc.dart';
import 'package:accumulate_api/src/model/address.dart';
import 'package:accumulate_api/src/model/adi.dart';
import 'package:accumulate_api/src/model/keys/key.dart' as acme;
import 'package:accumulate_api/src/model/keys/keybook.dart';
import 'package:accumulate_api/src/model/keys/keypage.dart';
import 'package:accumulate_api/src/model/tx.dart';
import 'package:accumulate_api/src/utils/marshaller.dart';
import 'package:accumulate_api/src/v2/requests/api_request_adi.dart';
import 'package:accumulate_api/src/v2/requests/api_request_burn_token.dart';
import 'package:accumulate_api/src/v2/requests/api_request_credit.dart';
import 'package:accumulate_api/src/v2/requests/api_request_data_account.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keybook.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keypage.dart';
import 'package:accumulate_api/src/v2/requests/api_request_keypage_update.dart';
import 'package:accumulate_api/src/v2/requests/api_request_metrics.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_account.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_create.dart';
import 'package:accumulate_api/src/v2/requests/api_request_token_issue.dart';
import 'package:accumulate_api/src/v2/requests/api_request_tx.dart';
import 'package:accumulate_api/src/v2/requests/api_request_tx_gen.dart';
import 'package:accumulate_api/src/v2/requests/api_request_tx_to.dart';
import 'package:accumulate_api/src/v2/requests/api_request_url.dart';
import 'package:accumulate_api/src/v2/requests/api_request_url_pagination.dart';
import 'package:accumulate_api/src/v2/requests/api_request_write_data.dart';
import 'package:accumulate_api/src/v2/requests/api_request_write_data_to.dart';
import 'package:accumulate_api/src/v2/responses/data.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

class ACMEApiV2 {
  String apiRPCUrl = "https://devnet.accumulatenetwork.io/";
  String apiPrefix = "v2";

  ACMEApiV2(this.apiRPCUrl, this.apiPrefix);

  ///
  ///
  Future<String?> callGetVersion() async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    // ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("version", []); //[apiRequestUrl]);
    res.result;

    String? ver = "";
    if (res.result != null) {
      ver = res.result["data"]["version"];
    }

    return ver;
  }

  ///
  ///
  Future<void> callGetMetrics(String type, String timeframe) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestMetrics apiRequestMetrics = new ApiRequestMetrics(type, timeframe);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("metrics", [apiRequestMetrics]);
    res.result;
  }

  ///
  /// "faucet":  m.Faucet,
  Future<dynamic> callFaucet(Address currAddr) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address!.toLowerCase());
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("faucet", [apiRequestUrl]);
    return res.result;
  }

  ///
  // RPC: "query" - query data
  Future<Data> callQuery(String? path) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query", [apiRequestUrl]);

    print("response ${res.result}");

    Data urlData = new Data();
    if (res != null) {
      String? accountType = res.result["type"];
      var mrState = res.result["merkleState"];
      int? nonce = mrState["count"];
      urlData.nonce = nonce;

      LinkedHashMap? dt = LinkedHashMap?.from(res.result["data"]); //res.result["data"];
      switch (accountType) {
        case "keyBook":
        case "tokenAccount":
          if (dt!.length > 2) {
            // process keypage
            String? url = res.result["data"]["url"];
            String? tokenUrl = res.result["data"]["tokenUrl"];
            String? balance = res.result["data"]["balance"];

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
          if (dt!.length > 2) {
            String? url = res.result["data"]["url"];
            String creditBalance = res.result["data"]["creditBalance"] ?? "0";

            urlData.url = url;
            urlData.tokenUrl = res.result["chainId"]; // as network name
            urlData.creditBalance = int.parse(creditBalance);
          }
          break;
        case "liteTokenAccount":
          if (dt!.length > 2) {
            String? url = res.result["data"]["url"];
            String? tokenUrl = res.result["data"]["tokenUrl"];
            String balance = res.result["data"]["balance"];
            int? txcount = res.result["data"]["txCount"];
            int? nonce = res.result["data"]["nonce"];
            String creditBalance = res.result["data"]["creditBalance"] ?? "0";

            urlData.url = url;
            urlData.tokenUrl = tokenUrl;
            urlData.balance = int.parse(balance);
            urlData.txcount = txcount;
            urlData.nonce = nonce;
            urlData.creditBalance = int.parse(creditBalance);
          }
          break;
        default:
          if (dt!.length > 2) {
            String? url = res.result["data"]["url"];
            urlData.url = url;
          }
          break;
      }
    }
    return urlData;
  }

  ///
  /// "query-directory":  m.QueryDirectory,
  Future<DataDirectory> callQueryDirectory(String path) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query-directory", [apiRequestUrl]);
    res.result;

    DataDirectory directoryData = new DataDirectory();
    directoryData.keybooksCount = 1;
    if (res != null) {
      String? accountType = res.result["type"];
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

  ///
  /// "query-chain":      m.QueryChain,
  Future<DataChain> callQueryChain(String path) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("query-directory", [apiRequestUrl]);
    res.result;

    DataChain directoryData = new DataChain();
    directoryData.keybooksCount = 1;
    if (res != null) {
      String? accountType = res.result["type"];
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

  ///
  /// "query-tx":         m.QueryTx,
  Future<Transaction?> callGetTokenTransaction(String? txhash) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;
    ApiRequestTx apiRequestHash = ApiRequestTx(txhash);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("query-tx", [apiRequestHash]);
    res.result;

    Transaction? tx;
    if (res != null) {
      var data = res.result["data"];
      String? type = res.result["type"];

      print(type);
      switch (type) {
        case "syntheticTokenDeposit":
        case "syntheticDepositTokens":
          String? txid = res.result["data"]["txid"];
          String? from = res.result["data"]["from"];
          String? to = res.result["data"]["to"];
          int amount = int.parse(res.result["data"]["amount"]);
          String? tokenUrl = res.result["data"]["tokenUrl"];

          tx = new Transaction("Outgoing", "", txid, from, to, amount, tokenUrl);
          break;
        case "addCredits":
          String? txid = res.result["data"]["txid"];
          String? from = res.result["sponsor"];
          String? to = res.result["data"]["recipient"];
          int amount = res.result["data"]["amount"];
          //String? tokenUrl = res.result["data"]["tokenUrl"];

          tx = new Transaction("Incoming", "add-credits", txid, from, to, amount, "");
          break;
        case "sendTokens":
          String? txid = res.result["txid"];
          String? from = res.result["data"]["from"];
          List to = res.result["data"]["to"];
          String? amount = "";
          String? urlRecepient = "";
          if (to != null) {
            amount = to[0]["amount"];
            urlRecepient = to[0]["url"];
          }

          tx = new Transaction("Outgoing", "transaction", txid, from, urlRecepient, int.parse(amount!), "acc://");
          break;
        case "syntheticDepositCredits":
          // TODO: handle differently from "addCredits"
          String? txid = res.result["data"]["txid"];
          tx = new Transaction("", "", txid, "", "", 0, ""); // use dummy structure for now
          break;
        case "createKeyPage":
          String? txid = res.result["txid"];
          String? from = res.result["origin"];
          String? to = res.result["data"]["url"];
          LinkedHashMap sigs = res.result["signatures"][0];
          int? dateNonce = sigs["nonce"];

          tx = new Transaction("Outgoing", "", txid, from, to, 0, "ACME");
          tx.created = dateNonce;

          break;
        case "acmeFaucet":
          String? txid = res.result["data"]["txid"];
          String? from = res.result["data"]["from"];
          String? to = res.result["data"]["url"];
          int amount = 1000000000;
          LinkedHashMap sigs = res.result["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = new Transaction("Incoming", "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;

          break;
        case "syntheticCreateChain":
          String? txid = res.result["data"]["txid"];
          String? sponsor = res.result["sponsor"];
          String? origin = res.result["origin"];
          LinkedHashMap sigs = res.result["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = new Transaction("Outgoing", "", txid, sponsor, origin, 0, "ACME");
          tx.created = dateNonce;
          break;
        case "createIdentity":
          // TODO: handle differently from "syntethicCreateChain"
          String? txid = res.result["data"]["txid"];
          tx = new Transaction("", "", txid, "", "", 0, ""); // use dummy structure for now
          break;
          break;
        default:
          print("  default handler");
          String? txid = res.result["data"]["txid"];
          String? from = res.result["data"]["from"];
          //ApiRespTxTo to = res.result["data"]["to"];
          LinkedHashMap dataTo = res.result["data"]["to"][0];
          String? to = dataTo["url"];
          int? amount = dataTo["amount"];
          //int amount = int.parse(res.result["data"]["amount"]);
          //String tokenUrl = res.result["data"]["tokenUrl"];
          //int? dateNonce = res.result["signer"]["nonce"];
          LinkedHashMap sigs = res.result["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = new Transaction("Outgoing", "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;
      }
    }

    return tx;
  }

  ///
  /// RPC: "query-tx-history" (in v1 - "token-account-history")
  Future<List<Transaction>> callGetTokenTransactionHistory(Address currAddr) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ApiRequestUrWithPagination apiRequestUrlWithPagination =
        new ApiRequestUrWithPagination(currAddr.address!.toLowerCase(), 0, 100);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("query-tx-history", [apiRequestUrlWithPagination]);
    res.result;

    // Collect transaction iteratively
    List<Transaction> txs = [];
    if (res != null) {
      var records = res.result["items"];

      if (records == null) {
        return [];
      }

      for (var i = 0; i < records.length; i++) {
        var tx = records[i];
        String? type = tx["type"];

        switch (type) {
          case "syntheticDepositTokens": // that's faucet
            String? txid = tx["txid"];
            String? amount = tx["data"]["amount"]; // AMOUNT INCOSISTENT, faucet returns String while other types int
            String? token = tx["data"]["token"];

            // if nothing that was a faucet
            Transaction txl = new Transaction("Incoming", "", txid, "", "", int.parse(amount!), "acc://$token");
            txs.add(txl);
            break;
          case "addCredits":
            String? txid = tx["txid"];
            int? amountCredits = tx["data"]["amount"]; // that's amount of credits
            int amount = (amountCredits! * 0.01).toInt() * 100000000; // in acmes

            Transaction txl = new Transaction("Incoming", "credits", txid, "", "", amount, "acc://ACME");
            txs.add(txl);
            break;
          case "sendTokens":
            String? txid = tx["txid"];
            String? from = tx["data"]["from"];
            List to = tx["data"]["to"];
            String? amount = "";
            String? urlRecepient = "";
            if (to != null) {
              amount = to[0]["amount"];
              urlRecepient = to[0]["url"];
            }

            Transaction txl =
                new Transaction("Outgoing", "transaction", txid, from, urlRecepient, int.parse(amount!), "acc://");
            txs.add(txl);
            break;
          case "syntheticCreateChain":
            String? txid = tx["txid"];
            int? amount = tx["data"]["amount"];
            String? token = tx["data"]["token"];

            Transaction txl = new Transaction("Outgoing", type!, txid, "", "", amount, "acc://$token");
            txs.add(txl);
            break;
          default:
            String? txid = tx["txid"];
            int? amount = tx["data"]["amount"];
            String? token = tx["data"]["token"];

            Transaction txl = new Transaction("Outgoing", type!, txid, "", "", amount, "acc://$token");
            txs.add(txl);
            break;
        }
      }
    }

    return txs;
  }

  ///
  /// "query-data":       m.QueryData,

  ///
  /// "query-data-set":   m.QueryDataSet,

  ///
  /// "query-key-index":  m.QueryKeyPageIndex,

  ///
  // "create-data-account":  m.ExecuteWith(func() PL { return new(protocol.CreateDataAccount) }),
  Future<dynamic> callCreateDataAccount(
      Address currAddr, IdentityADI parentAdi, String accountName, int timestamp, String? keybookName, bool? isScratch,
      [int? keyPageHeight]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = keyPageHeight ?? 1;
    int keyPageIndexInsideKeyBook = 0;

    // TODO: check if keybook name available
    // TODO: allow newly generated keypair

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(parentAdi.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(parentAdi.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: parentAdi.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: 0);

    // prepare payload
    String dtknPath = parentAdi.path! + "/" + accountName;
    ApiRequestDataAccount data = ApiRequestDataAccount(dtknPath, "", "", isScratch);

    print(dtknPath);

    ApiRequestRawTx_DataAccount tx = ApiRequestRawTx_DataAccount(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: parentAdi.path,
        origin: parentAdi.path,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: parentAdi.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryCreateDataAccount(tx);

    //print('Header:\n ${header.marshal()}');
    //print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    var res = await acmeApi.call("create-data-account", [tx]);
    return res.result;

    /*
    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String? simpleHash = res.result["simpleHash"];
      String? transactionHash = res.result["transactionHash"];
      String? envelopeHash = res.result["envelopeHash"];
      String? hash = res.result["hash"];
      int? code = res.result["code"];
      String? message = res.result["message"];

      print('Response: $message');
      if (code == 12) {}
    }

    return txid;*/
  }

  ///
  /// "create-adi":           m.ExecuteWith(func() PL { return new(protocol.IdentityCreate) }),
  Future<String?> callCreateAdi(Address currAddr, IdentityADI adiToCreate, int timestamp,
      [String? keybookName, String? keypageName]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    // TODO: check if keybook name available
    // TODO: allow newly generated keypair

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: currAddr.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: 1); //, index: 0);

    // prepare data
    ApiRequestADI data = ApiRequestADI(adiToCreate.path, currAddr.puk, keybookName ?? "", keypageName ?? "");

    ApiRequestRawTx_ADI tx = ApiRequestRawTx_ADI(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: currAddr.address,
        origin: currAddr.address,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: currAddr.address,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryCreateIdentity(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
    }

    return txid;
  }

  ///
  /// RPC: "token-account" - Create token account
  Future<String?> callCreateTokenAccount(
      Address currAddr, IdentityADI sponsorADI, String tokenAccountName, String keybookPath, int timestamp,
      [String? keyPuk,
      String? keyPik,
      int? keyPageHeight,
      String tokenUrl = "acc://acme",
      bool isScratch = false]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String? signerKey = currAddr.puk;
    String? sponsorPath = currAddr.address; //sponsorADI.path;

    int? keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;
    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik!));
      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage =
        ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: keyPageIndexInsideKeyBook); //, index: 0);

    // prepare payload
    ApiRequestTokenAccount data =
        ApiRequestTokenAccount(sponsorADI.path! + "/" + tokenAccountName, tokenUrl, keybookPath, isScratch);

    ApiRequestRawTx_TokenAccount tx = ApiRequestRawTx_TokenAccount(
        payload: data, signer: signer, origin: sponsorPath, signature: "", sponsor: sponsorPath, keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorPath,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryCreateTokenAccount(tx);

    print('Header:\n ${header.marshal()}');
    print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
    }

    return txid;
  }

  ///
  /// "create-key-book":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyBook) }),
  Future<Tuple2<String?, String>> callKeyBookCreate(
      IdentityADI sponsorADI, KeyBook keybook, List<String> pages, int timestamp,
      [String? keyPuk, String? keyPik, int? keyPageHeight, String? keybookPath]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int? keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String? signerKey = sponsorADI.puk;
    String? sponsorPath = sponsorADI.path;

    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik!));

      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);

    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook); // 1,0 - for defaults

    ApiRequestKeyBook data = new ApiRequestKeyBook(keybook.path, pages);

    ApiRequestRawTx_KeyBook tx = ApiRequestRawTx_KeyBook(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorADI.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryCreateKeyBook(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    String hash = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];

      //hash = res.result["hash"];

    }

    return Tuple2(txid, hash);
  }

  ///
  /// "create-key-page":      m.ExecuteWith(func() PL { return new(protocol.CreateKeyPage) }),
  Future<Tuple2<String?, String>> callKeyPageCreate(
      IdentityADI sponsorADI, KeyPage keypage, List<String> keys, int timestamp,
      [String? keyPuk, String? keyPik, int? keyPageHeight, String? keybookPath]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int? keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String? signerKey = sponsorADI.puk;
    String? sponsorPath = sponsorADI.path;

    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik!));

      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = sponsorADI.path;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);

    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook); // 1,0 - for defaults

    //prepare payload data
    var keypageKeys = keys.map((e) => KeySpecParams(e)).toList();
    ApiRequestKeyPage data = new ApiRequestKeyPage(keypage.path, keypageKeys);

    ApiRequestRawTx_KeyPage tx = ApiRequestRawTx_KeyPage(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorADI.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);

    List<int> dataBinary = tokenTx.marshalBinaryCreateKeyPage(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    String hash = "";
    if (res != null) {
      txid = res.result["txid"];
    }

    return Tuple2(txid, hash);
  }

  ///
  /// "update-key-page":      m.ExecuteWith(func() PL { return new(protocol.UpdateKeyPage) })
  Future<Tuple2<String?, String>> callKeyPageUpdate(KeyPage keypage, String operationName, String keyPuk, String keyPik,
      String newKeyPuk, int timestamp, int keyPageHeight) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(keyPuk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(keyPik));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String signerKey = keyPuk;
    String? sponsorPath = keypage.path;

    if (keyPuk != null) {
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      keypageHeightToUse = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = keypage.path;
      ;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);

    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook); // 1,0 - for defaults

    //prepare payload data
    ApiRequestKeyPageUpdate data = ApiRequestKeyPageUpdate(operationName, keyPuk, newKeyPuk, keypage.path);

    ApiRequestRawTx_KeyPageUpdate tx = ApiRequestRawTx_KeyPageUpdate(
        payload: data, signer: signer, signature: "", sponsor: sponsorPath, origin: sponsorPath, keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: keypage.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryKeyPageUpdate(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    String hash = "";
    if (res != null) {
      txid = res.result["txid"];
    }

    return Tuple2(txid, hash);
  }

  ///
  /// "send-tokens":          m.ExecuteWith(func() PL { return new(api.SendTokens) }, "From", "To"),
  Future<String?> callCreateTokenTransaction(Address addrFrom, Address addrTo, String amount, int timestamp,
      [acme.Key? providedKey, int? providedKeyPageChainHeight, int? keyPageIndexInsideKeyBook]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    var pukToUse;
    int? keypageHeightToUse = 1;
    int? keyPageIndexInsideKeyBook = 0;

    if (providedKey == null) {
      // use keys from account
      pukToUse = addrFrom.puk;
      publicKey = ed.PublicKey(HEX.decode(addrFrom.puk!));
      privateKey = ed.PrivateKey(HEX.decode(addrFrom.pikHex!));
      var keyPair = ed.KeyPair(privateKey, publicKey);
    } else {
      // use provided keys values
      pukToUse = providedKey.puk;
      publicKey = ed.PublicKey(HEX.decode(providedKey.puk!));
      privateKey = ed.PrivateKey(HEX.decode(providedKey.pikHex!));
      var keyPair = ed.KeyPair(privateKey, publicKey);
      keypageHeightToUse = providedKeyPageChainHeight;
    }

    //prepare data
    int amountToDeposit = (double.parse(amount) * 100000000).round().toInt(); // assume 8 decimal places
    ApiRequestTxToDataTo to = ApiRequestTxToDataTo(url: addrTo.address, amount: amountToDeposit);
    ApiRequestTxToData data =
        ApiRequestTxToData(to: [to], hash: "0000000000000000000000000000000000000000000000000000000000000000");

    Signer signer = Signer(publicKey: pukToUse, nonce: timestamp);

    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(
        height: keypageHeightToUse); // , index: keyPageIndexInsideKeyBook); // 1,0 - for defaults

    ApiRequestRawTx tx = ApiRequestRawTx(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: addrFrom.address,
        origin: addrFrom.address,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: addrFrom.address,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinarySendTokens(tx);

    log('Header:\n ${header.marshal()}');
    log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];
    }

    return txid;
  }

  ///
  /// "add-credits":          m.ExecuteWith(func() PL { return new(protocol.AddCredits) }),
  Future<String?> callAddCredits(Address currAddr, int amount, int timestamp,
      [KeyPage? currKeyPage, acme.Key? currKey]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = 1;
    String? currOrigin;

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    String? puk = currAddr.puk;
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
    publicKey = ed.PublicKey(HEX.decode(currAddr.puk!));
    privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex!));
    ///////////////

    // Because we can send to accounts and keybooks ath the same time
    ApiRequestCredits data;
    if (currKeyPage != null) {
      data = ApiRequestCredits(currKeyPage.path, amount);
      currOrigin = currAddr.address;
    } else {
      data = ApiRequestCredits(currAddr.address!.toLowerCase(), amount);
      currOrigin = currAddr.address;
    }

    Signer signer = Signer(publicKey: puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: 1, index: 0);

    ApiRequestRawTx_Credits tx = ApiRequestRawTx_Credits(
        payload: data,
        signer: signer,
        signature: "",
        origin: currAddr.address,
        sponsor: currAddr.address,
        keyPage: keyPageInfo);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: currAddr.address, nonce: timestamp, keyPageHeight: keypageHeightToUse, keyPageIndex: 0);
    List<int> dataBinary = tokenTx.marshalBinaryAddCredits(tx);

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];
    }
    return txid;
  }

  Future<String?> callCreateNewToken(IdentityADI sponsorADI, int timestamp, int keyPageHeight, String tokenName,
      String tokenSymbol, int tokenPrecision, int tokenInitialSupply) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keyPageIndexInsideKeyBook = 0;

    print("${sponsorADI.puk}");
    print("${sponsorADI.pikHex}");

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: sponsorADI.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keyPageHeight); //, index: 0);

    String tokenUrl = sponsorADI.path! + tokenName;
    String sponsorPath = sponsorADI.path!;

    // prepare data
    ApiRequestToken data = ApiRequestToken(tokenUrl, tokenSymbol, tokenPrecision, tokenInitialSupply.toString());

    ApiRequestRawTx_Token tx = ApiRequestRawTx_Token(
        origin: sponsorPath, sponsor: sponsorPath, payload: data, signer: signer, signature: "", keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorPath, nonce: timestamp, keyPageHeight: keyPageHeight, keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryCreateToken(tx);

    //log('Header:\n ${header.marshal()}');
    //log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    print(sig);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-token", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];

      print("Success create-token");
      print("API RESULT: ${res.result}");
    }

    return txid;
  }

  Future<String?> callIssueNewToken(IdentityADI sponsorADI, int timestamp, int keyPageHeight, String tokenUrl) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keyPageIndexInsideKeyBook = 0;

    print("${sponsorADI.puk}");
    print("${sponsorADI.pikHex}");
    print(tokenUrl);

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: sponsorADI.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keyPageHeight); //, index: 0);

    String sponsorPath = sponsorADI.path! + "/book0";

    // prepare data

    ApiRequestTokenIssue data = ApiRequestTokenIssue(tokenUrl, 10.toString());

    ApiRequestRawTx_TokenIssue tx = ApiRequestRawTx_TokenIssue(
        origin: sponsorPath, sponsor: sponsorPath, payload: data, signer: signer, signature: "", keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorPath, nonce: timestamp, keyPageHeight: keyPageHeight, keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryIssueTokens(tx);

    //log('Header:\n ${header.marshal()}');
    //log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    print(sig);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("issue-tokens", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];

      print("Success issue-token");
      print("API RESULT: ${res.result}");
    }

    return txid;
  }

  Future<String?> callBurnToken(
      IdentityADI sponsorADI, int timestamp, int keyPageHeight, String tokenUrl, int amount) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keyPageIndexInsideKeyBook = 0;

    print("${sponsorADI.puk}");
    print("${sponsorADI.pikHex}");
    print(tokenUrl);

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: sponsorADI.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keyPageHeight); //, index: 0);

    String sponsorPath = sponsorADI.path! + "/book0";

    // prepare data

    ApiRequestBurnToken data = ApiRequestBurnToken(amount.toString());

    ApiRequestRawTx_TokenBurn tx = ApiRequestRawTx_TokenBurn(
        origin: sponsorPath, sponsor: sponsorPath, payload: data, signer: signer, signature: "", keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: sponsorPath, nonce: timestamp, keyPageHeight: keyPageHeight, keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryBurnTokens(tx);

    //log('Header:\n ${header.marshal()}');
    //log('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    print(sig);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("burn-tokens", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];

      print("Success burn-token");
      print("API RESULT: ${res.result}");
    }

    return txid;
  }

  Future<String?> callAddCreditsWithSponsor(Address toAddr, Address fromAddr, int amount, int timestamp,
      [KeyPage? currKeyPage, acme.Key? currKey]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = 1;
    String? origin;
    String? sponsor;

    ed.PublicKey publicKey;
    ed.PrivateKey privateKey;
    String? puk = fromAddr.puk;
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
    puk = fromAddr.puk;
    publicKey = ed.PublicKey(HEX.decode(fromAddr.puk!));
    privateKey = ed.PrivateKey(HEX.decode(fromAddr.pikHex!));
    ///////////////

    // Because we can send to accounts and keybooks ath the same time
    ApiRequestCredits data;
    if (currKeyPage != null) {
      data = ApiRequestCredits(currKeyPage.path, amount);
      origin = fromAddr.address;
      sponsor = fromAddr.address;
    } else {
      data = ApiRequestCredits(toAddr.address!.toLowerCase(), amount);
      origin = fromAddr.address;
      sponsor = fromAddr.address;
    }

    Signer signer = Signer(publicKey: puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: 1, index: 0);

    ApiRequestRawTx_Credits tx = ApiRequestRawTx_Credits(
        payload: data, signer: signer, signature: "", origin: origin, sponsor: sponsor, keyPage: keyPageInfo);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header =
        TransactionHeader(origin: origin, nonce: timestamp, keyPageHeight: keypageHeightToUse, keyPageIndex: 0);
    List<int> dataBinary = tokenTx.marshalBinaryAddCredits(tx);

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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

    String? txid = "";
    if (res != null) {
      txid = res.result["txid"];
    }
    return txid;
  }

  Future<String?> callWriteData1(String dataAccountPath, IdentityADI parentAdi, String dataToWrite, int timestamp,
      [int? keyPageHeight, List<String>? tags]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = keyPageHeight ?? 1;
    int keyPageIndexInsideKeyBook = 0;

    // TODO: check if keybook name available
    // TODO: allow newly generated keypair

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(parentAdi.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(parentAdi.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: parentAdi.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: 0);

    // prepare payload

    List<String> hexExtIds = [];
    if (tags != null) {
      for (var i = 0; i < tags.length; i++) {
        String hexExtId = "";
        for (int j = 0; j < tags[i].length; j++) {
          hexExtId += tags[i].codeUnitAt(j).toRadixString(16);
        }

        hexExtIds.add(hexExtId);
      }
    }

    String hexData = "";
    for (int i = 0; i < dataToWrite.length; i++) {
      hexData += dataToWrite.codeUnitAt(i).toRadixString(16);
    }

    ApiRequestWriteData data = ApiRequestWriteData(hexData, hexExtIds);

    ApiRequestRawTx_WriteData tx = ApiRequestRawTx_WriteData(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: dataAccountPath,
        origin: dataAccountPath,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: parentAdi.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryWriteData(tx);

    print('Header:\n ${header.marshal()}');
    print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    var res = await acmeApi.call("write-data", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String? simpleHash = res.result["simpleHash"];
      String? transactionHash = res.result["transactionHash"];
      String? envelopeHash = res.result["envelopeHash"];
      String? hash = res.result["hash"];
      int? code = res.result["code"];

      print('Response: ${res.result}');
    }

    return txid;
  }

  Future<String?> callWriteData(
      String dataAccountPath, String dataToWrite, int timestamp, KeyPage currKeyPage, acme.Key currKey,
      [int? keyPageHeight, List<String>? tags]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = keyPageHeight ?? 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currKey.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currKey.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String? puk = currKey.puk;

    Signer signer = Signer(publicKey: puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: 0);

    // prepare payload

    List<String> hexExtIds = [];
    if (tags != null) {
      for (var i = 0; i < tags.length; i++) {
        String hexExtId = "";
        for (int j = 0; j < tags[i].length; j++) {
          hexExtId += tags[i].codeUnitAt(j).toRadixString(16);
        }

        hexExtIds.add(hexExtId);
      }
    }

    String hexData = "";
    for (int i = 0; i < dataToWrite.length; i++) {
      hexData += dataToWrite.codeUnitAt(i).toRadixString(16);
    }

    ApiRequestWriteData data = ApiRequestWriteData(hexData, hexExtIds);

    ApiRequestRawTx_WriteData tx = ApiRequestRawTx_WriteData(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: dataAccountPath,
        origin: dataAccountPath,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: dataAccountPath, //parentAdi.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryWriteData(tx);

    print('Header:\n ${header.marshal()}');
    print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    var res = await acmeApi.call("write-data", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String? simpleHash = res.result["simpleHash"];
      String? transactionHash = res.result["transactionHash"];
      String? envelopeHash = res.result["envelopeHash"];
      String? hash = res.result["hash"];
      int? code = res.result["code"];

      print('Response: ${res.result}');
    }

    return txid;
  }

  Future<String?> callWriteDataTo1(String dataAccountPath, IdentityADI parentAdi, String dataToWrite, int timestamp,
      [int? keyPageHeight]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = keyPageHeight ?? 1;
    int keyPageIndexInsideKeyBook = 0;

    // TODO: check if keybook name available
    // TODO: allow newly generated keypair

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(parentAdi.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(parentAdi.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: parentAdi.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: 0);

    // prepare payload

    ApiRequestWriteDataTo data = ApiRequestWriteDataTo(dataToWrite, dataAccountPath);

    ApiRequestRawTx_WriteDataTo tx = ApiRequestRawTx_WriteDataTo(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: parentAdi.path,
        origin: parentAdi.path,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: parentAdi.path,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryWriteDataTo(tx);

    print('Header:\n ${header.marshal()}');
    print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    var res = await acmeApi.call("write-data-to", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String? simpleHash = res.result["simpleHash"];
      String? transactionHash = res.result["transactionHash"];
      String? envelopeHash = res.result["envelopeHash"];
      String? hash = res.result["hash"];
      int? code = res.result["code"];

      print('Response: ${res.result}');
    }

    return txid;
  }

  Future<String?> callWriteDataTo(
      String dataAccountPath, String dataToWrite, int timestamp, KeyPage currKeyPage, acme.Key currKey,
      [int? keyPageHeight, List<String>? tags]) async {
    String ACMEApiUrl = apiRPCUrl + apiPrefix;

    int keypageHeightToUse = keyPageHeight ?? 1;
    int keyPageIndexInsideKeyBook = 0;

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currKey.puk!));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currKey.pikHex!));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String? puk = currKey.puk;

    Signer signer = Signer(publicKey: puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: keypageHeightToUse); //, index: 0);

    // prepare payload

    ApiRequestWriteDataTo data = ApiRequestWriteDataTo(dataToWrite, dataAccountPath);

    ApiRequestRawTx_WriteDataTo tx = ApiRequestRawTx_WriteDataTo(
        payload: data,
        signer: signer,
        signature: "",
        sponsor: dataAccountPath,
        origin: dataAccountPath,
        keyPage: keyPage);

    TokenTx tokenTx = TokenTx();
    TransactionHeader header = TransactionHeader(
        origin: dataAccountPath,
        nonce: timestamp,
        keyPageHeight: keypageHeightToUse,
        keyPageIndex: keyPageIndexInsideKeyBook);
    List<int> dataBinary = tokenTx.marshalBinaryWriteDataTo(tx);

    print('Header:\n ${header.marshal()}');
    print('Body: ${dataBinary}');

    // Generalized version of GenTransaction in Go
    ApiRequestTxGen txGen = ApiRequestTxGen([], header, dataBinary);
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
    var res = await acmeApi.call("write-data-to", [tx]);
    res.result;

    String? txid = "";
    if (res != null) {
      String? type = res.result["type"];

      // TODO: combine into single response type
      txid = res.result["txid"];
      String? simpleHash = res.result["simpleHash"];
      String? transactionHash = res.result["transactionHash"];
      String? envelopeHash = res.result["envelopeHash"];
      String? hash = res.result["hash"];
      int? code = res.result["code"];

      print('Response: ${res.result}');
    }

    return txid;
  }
}
