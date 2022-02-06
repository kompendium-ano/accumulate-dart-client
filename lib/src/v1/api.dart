import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:accumulate/src/utils/general.dart';
import 'package:accumulate/src/v1/model/native/address.dart';
import 'package:accumulate/src/v1/model/native/adi.dart';
import 'package:accumulate/src/v1/model/native/keys/keybook.dart';
import 'package:accumulate/src/v1/model/native/keys/keypage.dart';
import 'package:accumulate/src/v1/model/native/keys/key.dart' as acme;
import 'package:accumulate/src/v1/model/native/tx.dart';
import 'package:accumulate/src/v1/requests/adi/api_request_adi.dart';
import 'package:accumulate/src/v1/requests/api_request_credit.dart';
import 'package:accumulate/src/v1/requests/api_request_keybook.dart';
import 'package:accumulate/src/v1/requests/api_request_keypage.dart';
import 'package:accumulate/src/v1/requests/api_request_keypage_update.dart';
import 'package:accumulate/src/v1/requests/api_request_mask.dart';
import 'package:accumulate/src/v1/requests/api_request_metrics.dart';
import 'package:accumulate/src/v1/requests/api_request_token_account.dart';
import 'package:accumulate/src/v1/requests/api_request_tx_gen.dart';
import 'package:accumulate/src/v1/requests/api_request_url_pagination.dart';
import 'package:accumulate/src/v1/responses/resp_token_get.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hex/hex.dart';
import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

import '../json_rpc.dart';
import '../data_resp.dart';
import 'requests/api_request_tx.dart';
import 'requests/api_request_tx_to.dart';
import 'requests/api_request_url.dart';

class ACMIApi {

  String currentApiRPCUrl = "";
  String apiPrefix = "/v1";

  ACMIApi(this.currentApiRPCUrl, [this.apiPrefix]);

  // RPC: "get" - Get Data
  Future<Data> callGetData(String path) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path, false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("get", [apiRequestUrl]);
    res.result;

    Data urlData = new Data();
    if (res != null) {
      String accountType = res.result["type"];
      LinkedHashMap dt = res.result["data"];
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
    }
    return urlData;
  }

  // RPC: "get-directory" - Get Directory Data
  Future<DataDirectory> callGetDirectory(String path) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("get-directory", [apiRequestUrl]);
    res.result;

    DataDirectory directoryData = new DataDirectory();
    directoryData.keybooksCount = 1;
    if (res != null) {
      String accountType = res.result["type"];
      LinkedHashMap dt = res.result["data"];
      if (dt.length == 1) {
        int total = res.result["data"]["total"];
        //List<String> entries = res.result["data"]["entries"].cast<String>();
        //directoryData.entities = entries;
        // entries.length > 2
        if (total > 2) {
          directoryData.tokenAccountsCount = total - 2;
        }
      }
    }

    return directoryData;
  }

  // RPC: "chain" - Get Chain Data By Id
  Future<Data> callGetChainById(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    var hexEncodedAddr = HEX.encode(utf8.encode(currAddr.address.toLowerCase()));
    //ApiRequestUrl apiRequestUrl = new ApiRequestUrl(hexEncodedAddr, false);

    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("chain", [apiRequestUrl]);
    res.result;

    Data urlData = new Data();
    return urlData;
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // RPC: "adi" - Get ADI information
  Future<String> callGetAdi(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("adi", [apiRequestUrl]);
    res.result;

    String txid = "";
    if (res != null) {
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
    }
    return txid;
  }

  // RPC: "adi-create"
  Future<String> callCreateAdi(Address currAddr, IdentityADI adiToCreate, int timestamp,
      [String keybookName, String keypageName]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestADI data = new ApiRequestADI(adiToCreate.path, currAddr.puk, keybookName ?? "", keypageName ?? "");

    SignatureInfo signatureInfo =
        SignatureInfo(url: currAddr.address, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: currAddr.puk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: 1, index: 0);
    ApiRequestRawTx_ADI tx =
        ApiRequestRawTx_ADI(data: data, signer: signer, sig: "", sponsor: currAddr.address, keyPage: keyPage);

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

    tx.sig = sigRem; // update underlying structure

    ApiRequestRaw_ADI apiRequestSendTo = ApiRequestRaw_ADI(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("adi-create", [apiRequestSendTo]);
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

  // RPC:"token" - Returns information about Token
  // Response:
  Future<void> callGetToken(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("token", [apiRequestUrl]);
    res.result;
  }

  Future<String> callGetVersion() async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
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
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestMetrics apiRequestMetrics = new ApiRequestMetrics(type, timeframe);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("metrics", [apiRequestMetrics]);
    res.result;
  }

  // RPC: "token-create" - Creates new Token
  // Response:
  Future<void> callCreateToken(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("token-create", [apiRequestUrl]);
    res.result;
  }

  // RPC: "token-account" - Create token account
  // Response:
  Future<String> callCreateTokenAccount(
      Address currAddr, IdentityADI sponsorADI, String tokenAccountName, String keybookPath, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestTokenAccount data = new ApiRequestTokenAccount(sponsorADI.path + "/" + tokenAccountName, "acc://acme",
        keybookPath); // previously keybook defaulted as: sponsorADI.path + "/" + "book0"

    SignatureInfo signatureInfo =
        SignatureInfo(url: currAddr.address, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(currAddr.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(currAddr.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String signerKey = currAddr.puk;
    String sponsorPath = sponsorADI.path;

    int kpHeight = 1;
    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      kpHeight = keyPageHeight;
      signerKey = keyPuk;
      //sponsorPath = keybookPath;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: kpHeight, index: 0);
    ApiRequestRawTx_TokenAccount tx =
        ApiRequestRawTx_TokenAccount(data: data, signer: signer, sig: "", sponsor: sponsorPath, keyPage: keyPage);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareTransactionTokenAccount(tx);
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

    ApiRequestRaw_TokenAccount apiRequestSendTo = ApiRequestRaw_TokenAccount(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("token-account-create", [apiRequestSendTo]);
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

  // RPC: token-account-get
  // Response: {"data":{"balance":"2000000000","tokenURL":"dc/ACME","url":"acme-467dc69eb1212c2c864bffc75355629fe5ead46ff966e7d1/dc/ACME"},"type":"tokenAccount"}
  Future<void> callGetTokenAccount(String path) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path, false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("token-account", [apiRequestUrl]);

    String ver = "";
    if (res.result != null) {
      ver = res.result["data"]["version"];
    }

    res.result;
  }

  // RPC:""token-tx-create" -
  // Response:
  // int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
  // local:      1635066665211   // DateTime.now().toUtc().millisecondsSinceEpoch;
  // local:      1635076318      // (DateTime.now().millisecondsSinceEpoch / 1000).toInt();
  // remote:     1257894000      // uint64(time.Now().Unix())
  Future<String> callCreateTokenTransaction(Address addrFrom, Address addrTo, String amount, int timestamp,
      [acme.Key providedKey, int providedKeyPageChainHeight, int keyPageIndexInsideKeyBook]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    //prepare data
    int amountToDeposit = (double.parse(amount) * 100000000).round().toInt(); // assume 8 decimal places
    ApiRequestTxToDataTo to = ApiRequestTxToDataTo(url: addrTo.address, amount: amountToDeposit);
    ApiRequestTxToData data = ApiRequestTxToData(
        from: addrFrom.address, to: [to], hash: "0000000000000000000000000000000000000000000000000000000000000000");

    // On a Go side
    // gtx.SigInfo = new(transactions.SignatureInfo)
    // //the siginfo URL is the URL of the signer
    // gtx.SigInfo.URL = sender
    // //Provide a nonce, typically this will be queried from identity sig spec and incremented.
    // //since SigGroups are not yet implemented, we will use the unix timestamp for now.
    // gtx.SigInfo.Nonce = uint64(params.Tx.Timestamp)
    // //The following will be defined in the SigSpec Group for which key to use
    // gtx.SigInfo.SigSpecHt = 0
    // gtx.SigInfo.Priority = 0
    // gtx.SigInfo.PriorityIdx = 0
    SignatureInfo signatureInfo =
        SignatureInfo(url: addrFrom.address, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

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

    Signer signer = Signer(publicKey: pukToUse, nonce: timestamp);

    ApiRequestRawTxKeyPage keyPage =
        ApiRequestRawTxKeyPage(height: keypageHeightToUse, index: keyPageIndexInsideKeyBook ?? 0); // 1,0 - for defaults
    ApiRequestRawTx tx =
        ApiRequestRawTx(data: data, signer: signer, sig: "", sponsor: addrFrom.address, keyPage: keyPage);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareTransaction(tx);
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

    // sign message and retrieve a signature
    // Next step in Go codebase
    // ed := new(transactions.ED25519Sig)
    // err = ed.Sign(gtx.SigInfo.Nonce, pk, gtx.TransactionHash())
    // params.Sig.FromBytes(ed.GetSignature())
    //
    //
    // // Sign
    // // Returns the signature for the given message.  What happens is the message
    // // is hashed with sha256, then the hash is signed.  The signature of the hash
    // // is returned.
    // func (e *ED25519Sig) Sign(nonce uint64, privateKey []byte, hash []byte) error {
    // 	e.Nonce = nonce
    // 	nHash := append(common.Uint64Bytes(nonce), hash...)       // Add nonce to hash
    // 	s := ed25519.Sign(privateKey, nHash)                      // Sign the nonce+hash
    // 	e.PublicKey = append([]byte{}, privateKey[32:]...)        // Note that the last 32 bytes of a private key is the
    // 	if !bytes.Equal(e.PublicKey, privateKey[32:]) {           // Check that we have the proper keys to sign
    // 		return errors.New("privateKey cannot sign this struct") // Return error that the doesn't match
    // 	}
    // 	e.Signature = s // public key.  Save the signature. // Save away the signature.
    // 	return nil
    // }

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

    ApiRequestRaw apiRequestSendTo = ApiRequestRaw(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("token-tx-create", [apiRequestSendTo]);
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

  // RPC: "get" - Get Date
  Future<Data> callGetAdiDirectory(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("adi-directory", [apiRequestUrl]);
    res.result;

    Data urlData = new Data();
    if (res != null) {
      String accountType = res.result["type"];
      LinkedHashMap dt = res.result["data"];
      if (dt.length > 2) {
        String url = res.result["data"]["url"];
        String tokenUrl = res.result["data"]["tokenUrl"];
        String balance = res.result["data"]["balance"];
        int txcount = res.result["data"]["txCount"];
        int nonce = res.result["data"]["nonce"];
        String creditBalance = res.result["data"]["creditBalance"];

        urlData.url = url;
        urlData.tokenUrl = tokenUrl;
        urlData.balance = int.parse(balance);
        urlData.txcount = txcount;
        urlData.nonce = nonce;
        urlData.creditBalance = int.parse(creditBalance);
      }
    }
    return urlData;
  }

  // RPC: "token-tx"
  // Response:
  Future<Transaction> callGetTokenTransaction(String txhash) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    List<int> txhashB = txhash.codeUnits;
    //var txhashEncoded = HEX.encode(utf8.encode(txhash));
    ApiRequestTx apiRequestHash = new ApiRequestTx(txhash);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("token-tx", [apiRequestHash]);
    res.result;

    Transaction tx;
    if (res != null) {
      var data = res.result["data"];
      String type = res.result["type"];

      if (type == "syntheticTokenDeposit") {
        String txid = res.result["data"]["txid"];
        String from = res.result["data"]["from"];
        String to = res.result["data"]["to"];
        int amount = int.parse(res.result["data"]["amount"]);
        String tokenUrl = res.result["data"]["tokenUrl"];

        tx = new Transaction(type, "", txid, from, to, amount, tokenUrl);
      } else {
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

  // RPC: "token-account-history"
  // Response:
  Future<List<Transaction>> callGetTokenTransactionHistory(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    //var hexEncodedAddr = HEX.encode(utf8.encode(currAddr.address.toLowerCase()));
    ApiRequestUrWithPagination apiRequestUrlWithPagination =
        new ApiRequestUrWithPagination(currAddr.address.toLowerCase(), 1, 100);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    final res = await acmeApi.call("token-account-history", [apiRequestUrlWithPagination]);
    res.result;

    // Collect transaction iteratively
    List<Transaction> txs = [];
    if (res != null) {
      var data = res.result["data"];
      String type = res.result["type"];

      if (data != null) {
        for (var i = 0; i < data.length; i++) {
          var tx = data[i];

          var internalData = tx["data"];
          String txid = internalData["txid"];

          // if nothing that was a faucet
          Transaction txl = new Transaction("", "", txid, "", "", 0, "");
          txs.add(txl);
        }
      }
    }

    return txs;
  }

  // RPC: "faucet" - add 10 tokens with faucet functionality
  // Response:
  Future<String> callFaucet(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
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

  Future<String> callAddCredits(Address currAddr, int amount, int timestamp,
      [KeyPage currKeyPage, acme.Key currKey]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

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

  Future<String> callGetCredits(Address currAddr) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(currAddr.address.toLowerCase(), false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("credits", [apiRequestUrl]);
    res.result;

    String txid = "";
    if (res != null) {
      txid = res.result["data"]["txid"];
      String log = res.result["data"]["log"];
    }
    return txid;
  }

  Future<Tuple2<String, String>> callKeyBookCreate(
      IdentityADI sponsorADI, KeyBook keybook, List<String> pages, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight, String keybookPath]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestKeyBook data = new ApiRequestKeyBook(keybook.path, pages);

    SignatureInfo signatureInfo =
        SignatureInfo(url: keybook.path, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    String signerKey = sponsorADI.puk;
    String sponsorPath = sponsorADI.path;

    int kpHeight = 1;
    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      kpHeight = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = keybookPath;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPage = ApiRequestRawTxKeyPage(height: kpHeight, index: 0);

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

    ApiRequestRaw_KeyBook apiRequestSendTo = ApiRequestRaw_KeyBook(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-sig-spec-group", [apiRequestSendTo]);
    res.result;

    String txid = "";
    String hash = "";
    //debugPrint("========> " + res.toString());
    if (res != null) {
      //debugPrint("========> " + res.result.toString());

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

  Future<DataKeybook> callGetKeyBook(String path) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path, false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("sig-spec-group", [apiRequestUrl]);
    res.result;

    String mdRoot = "";
    DataKeybook dataKeybook = new DataKeybook();
    if (res != null) {
      mdRoot = res.result["data"]["mdRoot"];
      String accountType = res.result["type"]; //sigSpecGroup
      LinkedHashMap dt = res.result["data"];
      if (dt.length > 1) {
        int accType = dt['type'];
        dataKeybook.url = dt['url'];

        var dtSigSpecId = dt['sigSpecId'];
        var dtSigSpec = dt['sigSpecs']; //
      }
    }
    dataKeybook.mdroot = mdRoot;
    return dataKeybook;
  }

  Future<Tuple2<String, String>> callKeyPageCreate(
      IdentityADI sponsorADI, KeyPage keypage, List<String> keys, int timestamp,
      [String keyPuk, String keyPik, int keyPageHeight, String keybookPath]) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    var keysParam = keys.map((e) => KeySpecParams(e)).toList();
    ApiRequestKeyPage data = new ApiRequestKeyPage(keypage.path, keysParam);

    SignatureInfo signatureInfo =
        SignatureInfo(url: keypage.path, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(sponsorADI.puk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(sponsorADI.pikHex));
    var keyPair = ed.KeyPair(privateKey, publicKey);
    String signerKey = sponsorADI.puk;
    String sponsorPath = sponsorADI.path;

    int kpHeight = 1;
    if (keyPuk != null) {
      // user submitted a keybook to identify how to connect
      publicKey = ed.PublicKey(HEX.decode(keyPuk));
      privateKey = ed.PrivateKey(HEX.decode(keyPik));
      kpHeight = keyPageHeight;
      signerKey = keyPuk;
      sponsorPath = keybookPath;
    }

    Signer signer = Signer(publicKey: signerKey, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: kpHeight, index: 0);
    ApiRequestRawTx_KeyPage tx =
        ApiRequestRawTx_KeyPage(data: data, signer: signer, sig: "", sponsor: sponsorPath, keypageInfo: keyPageInfo);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareKeyPage(tx);
    List<int> dataBinary = prep.dataPayload;

    //debugPrint("kp: =====> ");

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
    //debugPrint("kp: =====> 2");
    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));
    //debugPrint("kp: =====> 3");
    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.sig = sigRem; // update underlying structure
    //debugPrint("kp: =====> 4");
    ApiRequestRaw_KeyPage apiRequestSendTo = ApiRequestRaw_KeyPage(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("create-sig-spec", [apiRequestSendTo]);
    res.result;

    String txid = "";
    String hash = "";
    //debugPrint("========> " + res.toString());
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

  Future<DataKeyPage> callGetKeyPage(String path) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";
    ApiRequestUrl apiRequestUrl = new ApiRequestUrl(path, false);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("sig-spec", [apiRequestUrl]);
    res.result;

    String mdRoot = "";
    DataKeyPage dataKeyPage = new DataKeyPage();
    if (res != null) {
      mdRoot = res.result["data"]["mdRoot"];
      String accountType = res.result["type"]; //sigSpecGroup
      LinkedHashMap dt = res.result["data"];
      if (dt.length > 1) {
        var accType = dt['type'];
        dataKeyPage.url = dt['url'];
        dataKeyPage.balanceCredits = dt['creditBalance'];

        var dtSigSpecId = dt['sigSpecId'];
        var dtSigSpec = dt['sigSpecs'];
      }
    }
    dataKeyPage.mdroot = mdRoot;
    return dataKeyPage;
  }

  Future<Tuple2<String, String>> callKeyPageUpdate(KeyPage keypage, String operationName, String keyPuk, String keyPik,
      String newKeyPuk, int timestamp, int keyPageHeight) async {
    String ACMEApiUrl = currentApiRPCUrl + "/v1";

    ApiRequestKeyPageUpdate data = new ApiRequestKeyPageUpdate(operationName, "", newKeyPuk);

    SignatureInfo signatureInfo =
        SignatureInfo(url: keypage.path, msHeight: 1, priorityIdx: 0, unused1: 0, unused2: timestamp);
    List<int> signInfoMarshaled = signatureInfo.marshal();

    ed.PublicKey publicKey = ed.PublicKey(HEX.decode(keyPuk));
    ed.PrivateKey privateKey = ed.PrivateKey(HEX.decode(keyPik));
    var keyPair = ed.KeyPair(privateKey, publicKey);

    Signer signer = Signer(publicKey: keyPuk, nonce: timestamp);
    ApiRequestRawTxKeyPage keyPageInfo = ApiRequestRawTxKeyPage(height: keyPageHeight, index: 0);
    ApiRequestRawTx_KeyPageUpdate tx = ApiRequestRawTx_KeyPageUpdate(
        data: data, signer: signer, sig: "", sponsor: keypage.path, keypageInfo: keyPageInfo);

    // Call our custom tx prepare function
    DataResp prep = await callPrepareKeyPageUpdate(tx);
    List<int> dataBinary = prep.dataPayload;

    //debugPrint("kp upd: =====> ");

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
    //debugPrint("kp: =====> 2");
    List<int> msg = [];
    msg.addAll(uint64ToBytes(timestamp)); //VLQ converted timestamp
    msg.addAll(txhashGen);
    Uint8List msgToSign = Uint8List.fromList(msg);

    // sign message which is (timestamp/nonce)+txHash
    Uint8List signature = ed.sign(privateKey, msgToSign); // should be nonce + transaction hash generated
    Uint8List signatureRem = ed.sign(privateKey, Uint8List.fromList(prep.nHash));
    //debugPrint("kp: =====> 3");
    // NB: sig is 64 bytes string created from hexing generated signature
    // var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    // sig = HEX.encode(bytes);
    String sig = "";
    String sigRem = "";
    sig = HEX.encode(signature);
    sigRem = HEX.encode(signatureRem);

    tx.sig = sigRem; // update underlying structure
    //debugPrint("kp: =====> 4");
    ApiRequestRaw_KeyPageUpdate apiRequestSendTo = ApiRequestRaw_KeyPageUpdate(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("key-page-update", [apiRequestSendTo]);
    res.result;

    // acc://zorro36/page2-2 check of updateKeyPage transaction failed: sponsor has not been assigned to an SSG

    String txid = "";
    String hash = "";
    //debugPrint("========> " + res.toString());
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

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // EXPERIMENTAL

  /// Custom API methods that we support internally
  ///  Always call staging server for now
  Future<List<int>> callMasked(int value) async {
    String ACMEApiUrl = "http://178.20.158.25:35554/v1";
    ApiRequestMask apiRequestMasked = new ApiRequestMask(value);
    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res = await acmeApi.call("mask", [apiRequestMasked]);
    res.result;

    String mask = "";
    if (res != null) {
      mask = res.result["data"]["mask"];
      String log = res.result["data"]["log"];
      //TokenAccountGetResponse resp = jsonDecode(res.result);
      //resp.data;
    }

    List<String> vals = mask.substring(1, mask.length - 1).split(' ');
    List<int> valuesInt = vals.map((e) => int.parse(e)).toList();
    return valuesInt;
  }

  /// Custom API methods that we support internally
  ///  Always call staging server for now
  Future<DataResp> callPrepareTransaction(ApiRequestRawTx tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://95.141.37.250:35554/v1";
    ApiRequestRaw apiRequestSendTo = ApiRequestRaw(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("token-tx-prepare", [apiRequestSendTo]);
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

  Future<DataResp> callPrepareTransactionAdi(ApiRequestRawTx_ADI tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://95.141.37.250:35554/v1";
    ApiRequestRaw_ADI apiRequestSendTo = ApiRequestRaw_ADI(tx: tx, wait: false);

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

  Future<DataResp> callPrepareTransactionTokenAccount(ApiRequestRawTx_TokenAccount tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://95.141.37.250:35554/v1"; // "http://178.20.158.25:56660/v1"; //
    ApiRequestRaw_TokenAccount apiRequestSendTo = ApiRequestRaw_TokenAccount(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("token-account-create-prepare", [apiRequestSendTo]);
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

  Future<DataResp> callPrepareKeyPage(ApiRequestRawTx_KeyPage tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://178.20.158.25:56660/v1";
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

  Future<DataResp> callPrepareKeyPageUpdate(ApiRequestRawTx_KeyPageUpdate tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://95.141.37.250:35554/v1"; //"http://178.20.158.25:56660/v1";
    ApiRequestRaw_KeyPageUpdate apiRequestSendTo = ApiRequestRaw_KeyPageUpdate(tx: tx, wait: false);

    JsonRPC acmeApi = JsonRPC(ACMEApiUrl, Client());
    var res;
    try {
      res = await acmeApi.call("keypage-update-prepare", [apiRequestSendTo]);
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

  Future<DataResp> callPrepareCredits(ApiRequestRawTx_Credits tx) async {
    String sig = "";
    var bytes = utf8.encode("60aa13125cbe0dd496a2f0248e6a46c04b799c160734b248e83eb4573ca4d560");
    bytes = utf8.encode("0000000000000000000000000000000000000000000000000000000000000000");
    sig = HEX.encode(bytes);
    tx.sig = sig; // dummy sig

    String ACMEApiUrl = "http://95.141.37.250:35554/v1";
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
