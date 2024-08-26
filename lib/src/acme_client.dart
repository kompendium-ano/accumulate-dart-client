// lib\src\acme_client.dart

import "dart:async";
import 'dart:collection';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:hex/hex.dart';

import 'client/acc_url.dart';
import 'model/api_types.dart';
import 'model/query_transaction_response_model.dart' as query_trx_res_model;
import 'model/tx.dart' as txModel;
import "payload.dart";
import "payload_b.dart";
import 'rpc_client.dart';
import "transaction.dart";
import 'client/tx_signer.dart';

class ACMEClient {
  late RpcClient _rpcClient;

  ACMEClient(String endpoint) {
    _rpcClient = RpcClient(endpoint);
  }

  Future<Map<String, dynamic>> call(String method,
      [Map<String, dynamic>? params, bool? supressLog]) {
    return _rpcClient.call(method, params, supressLog);
  }

  Future<Map<String, dynamic>> _execute(
      AccURL principal, Payload payload, TxSigner signer) async {
    HeaderOptions? options;
    if (payload.memo != null) {
      options = HeaderOptions();
      options.memo = payload.memo;
    }

    if (payload.metadata != null) {
      if (options == null) {
        options = HeaderOptions();
      }
      options.metadata = payload.metadata;
    }

    final header = Header(principal, options);
    final tx = Transaction(payload, header);
    await tx.sign(signer);

    return execute(tx);
  }

  // Adjust execute method to accept suppressLog
  Future<Map<String, dynamic>> execute(Transaction tx,
      {bool suppressLog = false}) {
    return call("execute", tx.toTxRequest().toMap, suppressLog);
  }

  Future<Map<String, dynamic>> executeDirect(Map<String, dynamic> params) {
    return call("execute-direct", params);
  }

  /////////////////////////////////////////////////////////////////////////////////////////////////

  Future<Map<String, dynamic>> queryAcmeOracle() {
    return call("describe");
  }

  Future<Map<String, dynamic>> queryData(dynamic url, [String? entryHash]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    if (entryHash != null && entryHash.isNotEmpty) {
      params.addAll({"entryHash": entryHash});
    }
    return call("query-data", params);
  }

  Future<Map<String, dynamic>> queryAnchor(String anchor) {
    return this.queryUrl(ANCHORS_URL.toString() + ('/#anchor/$anchor'));
  }

  Future<Map<String, dynamic>> queryUrl(dynamic url, [QueryOptions? options]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query", params);
  }

  Future<Map<String, dynamic>> queryTx(String txRef,
      [TxQueryOptions? options]) {
    String paramName = txRef.startsWith("acc://") ? "txIdUrl" : "txid";
    paramName = "txid";
    var txId = "";
    Map<String, dynamic> params = {};
    if (txRef.startsWith("acc://")) {
      txId = txRef.substring(6).split("@")[0];
    }
    params.addAll({paramName: txId});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-tx", params);
  }

  Future<Map<String, dynamic>> queryTxByUrl(String txId,
      [TxQueryOptions? options]) {
    String paramName = "txIdUrl";
    Map<String, dynamic> params = {};
    params.addAll({paramName: txId});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-tx", params);
  }

  Future<Map<String, dynamic>> queryTxHistory(
      dynamic url, QueryPagination pagination, TxHistoryQueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }
    return call("query-tx-history", params, true);
  }

  Future<Map<String, dynamic>> queryDataSet(
      dynamic url, QueryPagination pagination, QueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-data-set", params);
  }

  Future<Map<String, dynamic>> queryKeyPageIndex(dynamic url, dynamic key) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll({"key": key is String ? key : HEX.encode(key)});

    return call("query-key-index", params);
  }

  Future<Map<String, dynamic>> queryMinorBlocks(String url,
      QueryPaginationForBlocks pagination, MinorBlocksQueryOptions? options,
      [bool? supressLog]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }
    return call("query-minor-blocks", params, supressLog);
  }

  Future<Map<String, dynamic>> queryMajorBlocks(String url,
      QueryPaginationForBlocks pagination, MinorBlocksQueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }
    return call("query-major-blocks", params);
  }

  Future<int> querySignerVersion(
      dynamic signer, Uint8List? publicKeyHash) async {
    AccURL signerUrl;
    Uint8List pkh;
    if (signer is AccURL) {
      signerUrl = signer;
      if (publicKeyHash == null || publicKeyHash.isEmpty) {
        throw Exception("Missing public key hash");
      }
      pkh = publicKeyHash;
    } else {
      signerUrl = signer.url;
      pkh = signer.publicKeyHash;
    }

    Map<String, dynamic> res = await queryKeyPageIndex(signerUrl, pkh);
    res = await queryUrl(res["result"]["data"]["keyPage"]);
    return res["result"]["data"]["version"];
  }

  Future<Map<String, dynamic>> queryDirectory(
      dynamic url, QueryPagination pagination, QueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-directory", params);
  }

  waitOnTx(int startTime, String txId, [WaitTxOptions? options]) async {
    Completer completer = Completer();

    int timeout = options?.timeout ?? 30000;
    final pollInterval = options?.pollInterval ?? 1000;
    final ignoreSyntheticTxs = options?.ignoreSyntheticTxs ?? false;

    try {
      final resp = await queryTx(txId);
      query_trx_res_model.QueryTransactionResponseModel
          queryTransactionResponseModel =
          query_trx_res_model.QueryTransactionResponseModel.fromJson(resp);

      if (queryTransactionResponseModel.result != null) {
        query_trx_res_model.QueryTransactionResponseModelResult result =
            queryTransactionResponseModel.result!;
        if (result.status != null) {
          if (result.status!.delivered!) {
            if (result.status!.failed != null) {
              if (result.status!.failed!) {
                print("${result.status?.toJson()}");
                completer.complete(false);
              }
            }

            log("${result.status!.delivered!} ${result.syntheticTxids}");
            if (ignoreSyntheticTxs) {
              completer.complete(true);
            } else {
              if (result.syntheticTxids!.isNotEmpty) {
                int nowTime = DateTime.now().millisecondsSinceEpoch;
                if (nowTime - startTime < timeout) {
                  sleep(Duration(milliseconds: pollInterval));
                  completer.complete(
                      await waitOnTx(startTime, result.syntheticTxids!.first));
                } else {
                  completer.complete(false);
                }
              } else {
                completer.complete(true);
              }
            }
          } else {
            int nowTime = DateTime.now().millisecondsSinceEpoch;
            if (nowTime - startTime < timeout) {
              sleep(Duration(milliseconds: pollInterval));
              completer.complete(await waitOnTx(startTime, txId));
            } else {
              completer.complete(false);
            }
          }
        } else {
          int nowTime = DateTime.now().millisecondsSinceEpoch;
          if (nowTime - startTime < timeout) {
            sleep(Duration(milliseconds: pollInterval));
            completer.complete(await waitOnTx(startTime, txId));
          } else {
            completer.complete(false);
          }
        }
      } else {
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        if (nowTime - startTime < timeout) {
          sleep(Duration(milliseconds: pollInterval));
          completer.complete(await waitOnTx(startTime, txId));
        } else {
          completer.complete(false);
        }
      }
    } catch (e) {
      // Do not retry on definitive transaction errors
      if (e is TxError) {
        //rethrow;
        completer.completeError(false);
      }

      int nowTime = DateTime.now().millisecondsSinceEpoch;
      if (nowTime - startTime < timeout) {
        sleep(Duration(milliseconds: pollInterval));
        completer.complete(await waitOnTx(startTime, txId));
      } else {
        print("last complete");
        completer.complete(false);
      }
    }

    return completer.future;
  }

  Future<Map<String, dynamic>> addCredits(
      dynamic principal, AddCreditsParam addCredits, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), AddCredits(addCredits), signer);
  }

  Future<Map<String, dynamic>> addValidator(
      dynamic principal, AddValidatorParam addValidator, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), AddValidator(addValidator), signer);
  }

  Future<Map<String, dynamic>> burnTokens(
      dynamic principal, BurnTokensParam burnTokens, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), BurnTokens(burnTokens), signer);
  }

  Future<Map<String, dynamic>> createDataAccount(dynamic principal,
      CreateDataAccountParam createDataAccount, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateDataAccount(createDataAccount), signer);
  }

  Future<Map<String, dynamic>> createIdentity(
      dynamic principal, CreateIdentityParam createIdentity, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateIdentity(createIdentity), signer);
  }

  Future<Map<String, dynamic>> createKeyBook(
      dynamic principal, CreateKeyBookParam createKeyBook, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateKeyBook(createKeyBook), signer);
  }

  Future<Map<String, dynamic>> createKeyPage(
      dynamic principal, CreateKeyPageParam createKeyPage, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateKeyPage(createKeyPage), signer);
  }

  Future<Map<String, dynamic>> createToken(
      dynamic principal, CreateTokenParam createToken, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateToken(createToken), signer);
  }

  Future<Map<String, dynamic>> createTokenAccount(dynamic principal,
      CreateTokenAccountParam createTokenAccount, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateTokenAccount(createTokenAccount), signer);
  }

  Future<Map<String, dynamic>> issueTokens(
      dynamic principal, IssueTokensParam issueTokens, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), IssueTokens(issueTokens), signer);
  }

  Future<Map<String, dynamic>> removeValidator(
      dynamic principal, RemoveValidatorArg removeValidator, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), RemoveValidator(removeValidator), signer);
  }

  Future<Map<String, dynamic>> sendTokens(
      dynamic principal, SendTokensParam sendTokens, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), SendTokens(sendTokens), signer);
  }

  Future<Map<String, dynamic>> updateAccountAuth(dynamic principal,
      UpdateAccountAuthParam updateAccountAuthParam, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        UpdateAccountAuth(updateAccountAuthParam), signer);
  }

  Future<Map<String, dynamic>> updateKey(
      dynamic principal, UpdateKeyParam updateKey, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), UpdateKey(updateKey), signer);
  }

  Future<Map<String, dynamic>> updateKeyPage(dynamic principal,
      UpdateKeyPageParam updateKeyPageParam, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), UpdateKeyPage(updateKeyPageParam), signer);
  }

  Future<Map<String, dynamic>> updateValidatorKey(dynamic principal,
      UpdateValidatorKeyParam updateValidatorKey, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        UpdateValidatorKey(updateValidatorKey), signer);
  }

  Future<Map<String, dynamic>> writeData(
      dynamic principal, WriteDataParam writeData, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), WriteData(writeData), signer);
  }

  Future<Map<String, dynamic>> faucet(AccURL url) {
    return call("faucet", {
      "url": url.toString(),
    });
  }

  Future<Map<String, dynamic>> faucetSimple(String url) {
    return call("faucet", {
      "url": url,
    });
  }

  Future<Map<String, dynamic>> status() {
    return call("status");
  }

  Future<Map<String, dynamic>> version() {
    return call("version");
  }

  Future<Map<String, dynamic>> describe() {
    return call("describe");
  }

  Future<Map<String, dynamic>> metrics(String metric, int duration) {
    return call("metrics", {
      "metric": metric,
      "duration": duration,
    });
  }

  Future<int> valueFromOracle() async {
    int price = 0;
    try {
      final oracle = await queryAcmeOracle();
      price = oracle["result"]["values"]["oracle"]["price"];
    } catch (e) {
      print("Not reacheable =====>>> $e");
    }
    return price;
  }

  Future<List<int>> getAdiSlidingFee() async {
    final networkParameters = await describe();
    List<int> adiSlidingFeeTable = [];
    var ds = networkParameters["result"]["values"]["globals"]["feeSchedule"]
        ["createIdentitySliding"];
    adiSlidingFeeTable = List<int>.from(ds);
    return adiSlidingFeeTable;
  }

  ///
  /// "query-tx":         m.QueryTx,
  Future<txModel.Transaction?> callGetTokenTransaction(String? txhash,
      [String? addr, bool? isLookupByUrl]) async {
    var res;
    if (isLookupByUrl != null) {
      // NB: this is needed because Testnet not working
      //     with hash anymore but
      res = await queryTxByUrl(txhash!);
    } else {
      res = await queryTx(txhash!);
    }

    txModel.Transaction? tx;
    if (res != null) {
      var data = res['result']["data"];
      String? type = res['result']["type"];

      print(type);
      switch (type) {
        case "syntheticTokenDeposit":
          int amount = int.parse(res['result']["data"]["amount"]);
          break;
        case "syntheticDepositTokens":
          String? txid = res['result']["txid"];
          String? from = res['result']["data"]["source"];
          String? to = res['result']["origin"];
          int amount = int.parse(res['result']["data"]["amount"]);
          String? tokenUrl = res['result']["data"]["token"];

          tx = txModel.Transaction(
              "Outgoing", "send_token", txid, from, to, amount, tokenUrl);
          break;
        case "addCredits":
          String amount = res['result']["data"]["amount"];
          int oracle = res['result']["data"]["oracle"];
          //int creditsVisual = (amount * oracle)! * 0.0000000001; // reverse formula

          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["sponsor"];
          String? to = res['result']["data"]["recipient"];
          int creditsRawAmount = int.parse(amount);
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? ts = sigs["timestamp"];

          tx = txModel.Transaction("Incoming", "add-credits", txid, from, to,
              creditsRawAmount, "credits");
          tx.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          break;
        case "sendTokens":
          String? txid = res['result']["txid"];
          String? from = res['result']["data"]["from"];
          List to = res['result']["data"]["to"];
          String? amount = "";
          String? urlRecepient = "";
          amount = to[0]["amount"];
          urlRecepient = to[0]["url"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? ts = sigs["timestamp"];

          tx = txModel.Transaction("Outgoing", "send_token", txid, from,
              urlRecepient, int.parse(amount!), "acc://");
          tx.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          break;
        case "syntheticDepositCredits":
          String? txid = res['result']["data"]["txid"];
          tx = txModel.Transaction(
              "", "", txid, "", "", 0, ""); // use dummy structure for now
          break;
        case "createKeyPage":
          String? txid = res['result']["txid"];
          String? from = res['result']["origin"];
          String? to = res['result']["data"]["url"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["nonce"];

          tx = txModel.Transaction("Outgoing", "", txid, from, to, 0, "ACME");
          tx.created = dateNonce;

          break;
        case "acmeFaucet":
          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["data"]["from"];
          String? to = res['result']["data"]["url"];
          int amount = 1000000000;
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? ts = sigs["timestamp"];

          tx = txModel.Transaction(
              "Incoming", "", txid, from, to, amount, "ACME");
          tx.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;

          break;
        case "syntheticCreateChain":
          String? txid = res['result']["data"]["txid"];
          String? sponsor = res['result']["sponsor"];
          String? origin = res['result']["origin"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = txModel.Transaction(
              "Outgoing", "", txid, sponsor, origin, 0, "ACME");
          tx.created = dateNonce;
          break;
        case "createIdentity":
          // TODO: handle differently from "syntethicCreateChain"
          String? txid = res['result']["data"]["txid"];
          tx = txModel.Transaction(
              "", "", txid, "", "", 0, ""); // use dummy structure for now
          break;
        case "systemGenesis":
          String? txid = res['result']["data"]["txid"];
          String? origin = res['result']["origin"];
          if (addr != null && addr != "") {
            origin = addr;
          }

          QueryPaginationForBlocks queryParams = QueryPaginationForBlocks();
          queryParams.start = 0;
          queryParams.limit = 1;

          MinorBlocksQueryOptions queryFilter = MinorBlocksQueryOptions()
            ..txFetchMode = 0
            ..blockFilterMode = 1;

          var majorBlocks = await queryMajorBlocks(
              "acc://ACME", queryParams, queryFilter); // "acc://dn.acme"
          var blockInfo = majorBlocks["result"]["items"][0];

          var blockTime = blockInfo["majorBlockTime"];
          var blockTimeD = DateTime.parse(blockTime);

          tx = txModel.Transaction("Incoming", "system_genesis", txid,
              "acc://ACME", origin, 0, "acc://");
          tx.created = blockTimeD.millisecondsSinceEpoch;
          break;

        case "updateAccountAuth":
          String? txid = res['result']["txid"];
          String? sponsor = res['result']["sponsor"];
          String? origin = res['result']["origin"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["timestamp"];
          String? status = res['result']["status"]["code"];

          tx = txModel.Transaction("Outgoing", "update-account-auth", txid,
              sponsor, origin, 0, "ACME");
          tx.created = dateNonce;
          tx.status = status;
          break;

        case "createTokenAccount":
          print("  create token account");
          String? txid = res['result']["txid"];
          String? sponsor = res['result']["sponsor"];
          String? origin = res['result']["origin"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["timestamp"];
          int? dateNonce2 = DateTime.fromMicrosecondsSinceEpoch(dateNonce!)
              .millisecondsSinceEpoch;
          String? status = res['result']["status"]["code"];

          tx = txModel.Transaction("Outgoing", "token-account-create", txid,
              sponsor, origin, 0, "ACME");
          tx.created = dateNonce;
          tx.status = status;
          break;
        default:
          print("  default handler");
          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["data"]["from"];
          //ApiRespTxTo to = res.result["data"]["to"];
          LinkedHashMap dataTo = res['result']["data"]["to"][0];
          String? to = dataTo["url"];
          int? amount = dataTo["amount"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? ts = sigs["timestamp"];

          tx = txModel.Transaction(
              "Outgoing", "", txid, from, to, amount, "ACME");
          tx.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
      }
    }

    return tx;
  }

  ///
  /// RPC: "query-tx-history" (in v1 - "token-account-history")
  Future<List<txModel.Transaction>> callGetTokenTransactionHistory(String path) async {
    QueryPagination queryPagination = QueryPagination();
    queryPagination.start = 0;
    queryPagination.count = 100;

    TxHistoryQueryOptions txHistoryQueryOptions = TxHistoryQueryOptions();

    // Log the RPC request
    print("callGetTokenTransactionHistory | Sending RPC request with path: $path");
    print("callGetTokenTransactionHistory | QueryPagination: start=${queryPagination.start}, count=${queryPagination.count}");
    print("callGetTokenTransactionHistory | TxHistoryQueryOptions: $txHistoryQueryOptions");

    final res = await queryTxHistory(path, queryPagination, txHistoryQueryOptions);

    // Log the RPC response
    print("callGetTokenTransactionHistory | Received response: $res");

    // Safely access 'result' and 'items'
    var records = res['result']?["items"];

    if (records == null) {
      print("callGetTokenTransactionHistory | No records found (items is null) in the response for path: $path");
      return [];
    }

    print("callGetTokenTransactionHistory | Number of records found: ${records.length}");

    // Collect transactions iteratively
    List<txModel.Transaction> txs = [];
    for (var i = 0; i < records.length; i++) {
      var tx = records[i];
      String? type = tx["type"];

      // Log transaction details for debugging
      print("callGetTokenTransactionHistory | Processing transaction $i of type $type with data: $tx");


      switch (type) {
        case "faucet": // that's faucet
          String? txid = tx["txid"];
          String? amount = tx["data"][
              "amount"]; // AMOUNT INCOSISTENT, faucet returns String while other types int
          String? token = tx["data"]["token"];
          var sigs = tx["signatures"];
          var sig = sigs[sigs.length - 1];
          int? ts = sig["timestamp"];

          // if nothing that was a faucet
          txModel.Transaction txl = txModel.Transaction(
              "Incoming", "", txid, "", "", int.parse(amount!), "$token");

          // NB: yes, can be
          if (ts! == 1) {
            txl.created = 1667304000 * 1000;
          } else {
            txl.created =
                DateTime.fromMicrosecondsSinceEpoch(ts).millisecondsSinceEpoch;
          }
          txs.add(txl);
          break;
        case "addCredits":
          String? txid = tx["txid"];
          int? amountCredits = (tx["data"]["amount"] is String)
              ? int.parse(tx["data"]["amount"])
              : tx["data"]["amount"]; // that's amount of credits
          int amount = (amountCredits! * 0.01).toInt() * 10000; // in acmes
          LinkedHashMap sigs = tx["signatures"][0];
          int? ts = sigs["timestamp"];

          txModel.Transaction txl = txModel.Transaction(
              "Incoming", "add-credits", txid, "", "", amount, "credits");
          txl.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          txs.add(txl);
          break;
        case "sendTokens":
          String? txid = tx["txid"];
          String? from = tx["data"]["from"];
          List to = tx["data"]["to"];
          String? amount = "";
          String? urlRecepient = "";
          amount = to[0]["amount"];
          urlRecepient = to[0]["url"];
          LinkedHashMap sigs = tx["signatures"][0];
          int? ts = sigs["timestamp"];

          txModel.Transaction txl = txModel.Transaction(
              "Outgoing",
              "send_token",
              txid,
              from,
              urlRecepient,
              int.parse(amount!),
              "acc://");
          txl.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          txs.add(txl);
          break;
        case "syntheticCreateChain":
          String? txid = tx["txid"];
          int? amount = tx["data"]["amount"];
          String? token = tx["data"]["token"];

          txModel.Transaction txl = txModel.Transaction(
              "Outgoing", type!, txid, "", "", amount, "$token");
          txs.add(txl);
          break;
        case "burnTokens":
          String? txid = tx["txid"];
          String? prod = tx["produced"][0];
          int? amount = int.parse(tx["data"]["amount"]);
          String? token = prod!.split("@").last;

          txModel.Transaction txl = txModel.Transaction(
              "Outgoing", type!, txid, "", "", amount, "$token");
          txs.add(txl);
          break;
        case "systemGenesis":
          String? txid = tx["txid"];
          int? amount = tx["data"]["amount"];
          String? token = tx["data"]["token"];
          String? status = tx["status"]["code"];

          QueryPaginationForBlocks queryParams = QueryPaginationForBlocks();
          queryParams.start = 0;
          queryParams.limit = 1;

          MinorBlocksQueryOptions queryFilter = MinorBlocksQueryOptions()
            ..txFetchMode = 0
            ..blockFilterMode = 1;

          var majorBlocks =
              await queryMajorBlocks("acc://dn.acme", queryParams, queryFilter);
          var blockInfo = majorBlocks["result"]["items"][0];

          var blockTime = blockInfo["majorBlockTime"];
          var blockTimeD = DateTime.parse(blockTime);

          txModel.Transaction txl = txModel.Transaction(
              "Incoming",
              "system_genesis",
              txid,
              "acc://ACME",
              path,
              amount,
              "acc://ACME",
              status);
          txl.created = blockTimeD.millisecondsSinceEpoch;
          txs.add(txl);
          break;
        case "syntheticDepositTokens":
          String? txid = tx["txid"];
          String? amountIn = tx["data"]["amount"];
          String? token = tx["data"]["token"];
          String? status = tx["status"]["code"];
          var sigs = tx["signatures"];
          var sig = sigs[sigs.length - 1];
          int? ts = sig["timestamp"];

          String? from = tx["data"]["source"];

          int amount = int.parse(amountIn!);

          txModel.Transaction txl = txModel.Transaction("Incoming",
              "send_token", txid, from, path, amount, "$token", status);
          if (ts! == 1) {
            // Get Timestamp as time from block
            int height = tx["status"]["received"];
            String bvnFrom = tx["status"]["sourceNetwork"];
            String bvn = tx["status"]["destinationNetwork"];
            String bvnDest = "";

            QueryPaginationForBlocks queryParams = QueryPaginationForBlocks();
            queryParams.start = height;
            queryParams.limit = 10;

            MinorBlocksQueryOptions queryFilter = MinorBlocksQueryOptions()
              ..txFetchMode = 0
              ..blockFilterMode = 1;

            var minorBlocks =
                await queryMinorBlocks(bvn, queryParams, queryFilter);
            var blockInfo = minorBlocks["result"]["items"][0]; //our block start
            var blockTime = blockInfo["blockTime"];
            var blockTimeD = DateTime.parse(blockTime);

            txl.created = blockTimeD.millisecondsSinceEpoch;
          } else {
            txl.created =
                DateTime.fromMicrosecondsSinceEpoch(ts).millisecondsSinceEpoch;
          }

          txs.add(txl);
          break;
        case "updateAccountAuth":
          String? txid = tx["txid"];
          LinkedHashMap sigs = tx["signatures"][0];
          int? ts = sigs["timestamp"];
          String? sponsor = tx["sponsor"];
          String? origin = tx["origin"];

          txModel.Transaction txl = txModel.Transaction("Outgoing",
              "update-account-auth", txid, sponsor, origin, 0, "ACME");
          txl.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          txs.add(txl);
          break;
        case "createTokenAccount":
          String? txid = tx["txid"];
          LinkedHashMap sigs = tx["signatures"][0];
          int? ts = sigs["timestamp"];
          String? sponsor = tx["sponsor"];
          String? origin = tx["origin"];

          txModel.Transaction txl = txModel.Transaction("Outgoing",
              "token-account-create", txid, sponsor, origin, 0, "ACME");
          txl.created =
              DateTime.fromMicrosecondsSinceEpoch(ts!).millisecondsSinceEpoch;
          txs.add(txl);
          break;
        default:
          String? txid = tx["txid"];
          int? amount = tx["data"]["amount"];
          String? token = tx["data"]["token"];

          txModel.Transaction txl = txModel.Transaction(
              "Outgoing", type!, txid, "", "", amount, "$token");
          txs.add(txl);
          break;
      }
    }

    return txs;
  }

  Future<Map<String, dynamic>> factom(
      dynamic principal, FactomDataEntryParam factomParam, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), FactomDataEntry(factomParam), signer);
  }

  Future<Map<String, dynamic>> createLiteDataAccount(dynamic principal,
      CreateLiteDataAccountParam createLiteDataAccountParam, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateLiteDataAccount(createLiteDataAccountParam), signer);
  }

  Future<Map<String, dynamic>> writeDataTo(
      dynamic principal, WriteDataToParam writeDataToParam, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), WriteDataTo(writeDataToParam), signer);
  }
}
