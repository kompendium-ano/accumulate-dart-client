import "dart:async";
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'payload/update_account_auth.dart';

import 'payload/create_lite_data_account.dart';
import 'payload/factom.dart';

import 'payload/update_key_page.dart';

import 'model/address.dart';
import 'model/data.dart';
import 'model/query_transaction_response_model.dart' as query_trx_res_model;
import 'package:hex/hex.dart';

import "acc_url.dart";
import "acme.dart";
import "api_types.dart";
import "payload.dart";
import "payload/add_credits.dart";
import "payload/add_validator.dart";
import "payload/burn_tokens.dart";
import "payload/create_data_account.dart";
import "payload/create_identity.dart";
import "payload/create_key_book.dart";
import "payload/create_key_page.dart";
import "payload/create_token.dart";
import "payload/create_token_account.dart";
import "payload/issue_tokens.dart";
import "payload/remove_validator.dart";
import "payload/send_tokens.dart";


import "payload/update_key.dart";

import "payload/update_validator_key.dart";
import "payload/write_data.dart";
import "payload/write_data_to.dart";
import "rpc_client.dart";
import "transaction.dart";
import "tx_signer.dart";
import 'model/tx.dart' as txModel;

class ACMEClient {
  late RpcClient _rpcClient;

  ACMEClient(String endpoint) {
    _rpcClient = RpcClient(endpoint);
  }

  Future<Map<String, dynamic>> call(String method,
      [Map<String, dynamic>? params]) {
    return _rpcClient.call(method, params);
  }

  Future<Map<String, dynamic>> _execute(
      AccURL principal, Payload payload, TxSigner signer) async {
    HeaderOptions? options;
    if(payload.memo != null){
      options = HeaderOptions();
      options.memo = payload.memo;
      print("payload.memo ${payload.memo}");
    }

    if(payload.metadata != null){
      if(options == null){
        options = HeaderOptions();
      }
      options.metadata = payload.metadata;
      print("payload.metadata ${payload.metadata}");
    }

    final header = Header(principal,options);
    final tx = Transaction(payload, header);
    await tx.sign(signer);

    return execute(tx);
  }

  Future<Map<String, dynamic>> execute(Transaction tx) {
    return call("execute", tx.toTxRequest().toMap);
  }

  Future<Map<String, dynamic>> queryData(dynamic url, [String? entryHash]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    if (entryHash != null && entryHash!.isNotEmpty) {
      params.addAll({"entryHash": entryHash});
    }
    return call("query-data", params);
  }

  Future<Map<String, dynamic>> queryAnchor(String anchor){
  return this.queryUrl(ANCHORS_URL.append('#anchor/${anchor}'));
  }

  Future<Map<String, dynamic>> queryUrl(dynamic url, [QueryOptions? options]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query", params);
  }

  Future<Map<String, dynamic>> queryTx(String txId, [TxQueryOptions? options]) {

    final paramName = txId.startsWith("acc://") ? "txIdUrl" : "txid";

    Map<String, dynamic> params = {};
    /*if(txId.startsWith("acc://")){
      txId = txId.substring(6).split("@")[0];
    }*/
    params.addAll({paramName: txId});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-tx", params);
  }

  Future<Map<String, dynamic>> queryTxHistory(
      dynamic url, QueryPagination pagination,TxHistoryQueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }
    return call("query-tx-history", params);
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

  Future<Map<String, dynamic>> queryMinorBlocks(dynamic url,
      QueryPagination pagination, MinorBlocksQueryOptions? options) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
    if (options != null) {
      params.addAll(options.toMap);
    }
    return call("query-minor-blocks", params);
  }

  Future<Map<String, dynamic>> querySignerVersion(
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

    Map<String, dynamic> keyPage = await queryKeyPageIndex(signerUrl, pkh);

    return queryUrl(keyPage["url"]);
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
    return _execute(
        AccURL.toAccURL(principal), UpdateAccountAuth(updateAccountAuthParam), signer);
  }

  Future<Map<String, dynamic>> updateKey(
      dynamic principal, UpdateKeyParam updateKey, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), UpdateKey(updateKey), signer);
  }


  Future<Map<String, dynamic>> updateKeyPage(
      dynamic principal, UpdateKeyPageParam updateKeyPageParam, TxSigner signer) {
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

  Future<int> getValueFromOracle() async{
    final oracle = await describe();
    int price = oracle["result"]["values"]["oracle"]["price"];
    return price;
  }

  ///
  /// "query-tx":         m.QueryTx,
  Future<txModel.Transaction?> callGetTokenTransaction(String? txhash) async {
    final res = await queryTx(txhash!);

    txModel.Transaction? tx;
    if (res != null) {
      var data = res['result']["data"];
      String? type = res['result']["type"];

      print(type);
      switch (type) {
        case "syntheticTokenDeposit":
        case "syntheticDepositTokens":
          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["data"]["from"];
          String? to = res['result']["data"]["to"];
          int amount = int.parse(res['result']["data"]["amount"]);
          String? tokenUrl = res['result']["data"]["tokenUrl"];

          tx = txModel.Transaction("Outgoing", "", txid, from, to, amount, tokenUrl);
          break;
        case "addCredits":
          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["sponsor"];
          String? to = res['result']["data"]["recipient"];
          int amount = res['result']["data"]["amount"];
          //String? tokenUrl = res.result["data"]["tokenUrl"];

          tx = txModel.Transaction("Incoming", "add-credits", txid, from, to, amount, "");
          break;
        case "sendTokens":
          String? txid = res['result']["txid"];
          String? from = res['result']["data"]["from"];
          List to = res['result']["data"]["to"];
          String? amount = "";
          String? urlRecepient = "";
          if (to != null) {
            amount = to[0]["amount"];
            urlRecepient = to[0]["url"];
          }

          tx = txModel.Transaction("Outgoing", "transaction", txid, from, urlRecepient, int.parse(amount!), "acc://");
          break;
        case "syntheticDepositCredits":
        // TODO: handle differently from "addCredits"
          String? txid = res['result']["data"]["txid"];
          tx = txModel.Transaction("", "", txid, "", "", 0, ""); // use dummy structure for now
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
          int? dateNonce = sigs["Nonce"];

          tx = txModel.Transaction("Incoming", "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;

          break;
        case "syntheticCreateChain":
          String? txid = res['result']["data"]["txid"];
          String? sponsor = res['result']["sponsor"];
          String? origin = res['result']["origin"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = txModel.Transaction("Outgoing", "", txid, sponsor, origin, 0, "ACME");
          tx.created = dateNonce;
          break;
        case "createIdentity":
        // TODO: handle differently from "syntethicCreateChain"
          String? txid = res['result']["data"]["txid"];
          tx = txModel.Transaction("", "", txid, "", "", 0, ""); // use dummy structure for now
          break;
          break;
        default:
          print("  default handler");
          String? txid = res['result']["data"]["txid"];
          String? from = res['result']["data"]["from"];
          //ApiRespTxTo to = res.result["data"]["to"];
          LinkedHashMap dataTo = res['result']["data"]["to"][0];
          String? to = dataTo["url"];
          int? amount = dataTo["amount"];
          //int amount = int.parse(res.result["data"]["amount"]);
          //String tokenUrl = res.result["data"]["tokenUrl"];
          //int? dateNonce = res.result["signer"]["nonce"];
          LinkedHashMap sigs = res['result']["signatures"][0];
          int? dateNonce = sigs["Nonce"];

          tx = txModel.Transaction("Outgoing", "", txid, from, to, amount, "ACME");
          tx.created = dateNonce;
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



    final res = await queryTxHistory(path,queryPagination,txHistoryQueryOptions);


    // Collect transaction iteratively
    List<txModel.Transaction> txs = [];
    if (res != null) {
      var records = res['result']["items"];

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
            txModel.Transaction txl = txModel.Transaction("Incoming", "", txid, "", "", int.parse(amount!), "acc://$token");
            txs.add(txl);
            break;
          case "addCredits":
            String? txid = tx["txid"];
            int? amountCredits = (tx["data"]["amount"] is String)? int.parse(tx["data"]["amount"]):tx["data"]["amount"]; // that's amount of credits
            int amount = (amountCredits! * 0.01).toInt() * 100000000; // in acmes

            txModel.Transaction txl = txModel.Transaction("Incoming", "credits", txid, "", "", amount, "acc://ACME");
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

            txModel.Transaction txl = txModel.Transaction("Outgoing", "transaction", txid, from, urlRecepient, int.parse(amount!), "acc://");
            txs.add(txl);
            break;
          case "syntheticCreateChain":
            String? txid = tx["txid"];
            int? amount = tx["data"]["amount"];
            String? token = tx["data"]["token"];

            txModel.Transaction txl = txModel.Transaction("Outgoing", type!, txid, "", "", amount, "acc://$token");
            txs.add(txl);
            break;
          default:
            String? txid = tx["txid"];
            int? amount = tx["data"]["amount"];
            String? token = tx["data"]["token"];

            txModel.Transaction txl = txModel.Transaction("Outgoing", type!, txid, "", "", amount, "acc://$token");
            txs.add(txl);
            break;
        }
      }
    }

    return txs;
  }


  Future<Map<String, dynamic>> factom(
      dynamic principal, FactomParam factomParam, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), Factom(factomParam), signer);
  }

  Future<Map<String, dynamic>> createLiteDataAccount(dynamic principal,
      CreateLiteDataAccountParam createLiteDataAccountParam, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateLiteDataAccount(createLiteDataAccountParam), signer);
  }

  Future<Map<String, dynamic>> writeDataTo(
      dynamic principal, WriteDataToParam writeDataToParam, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), WriteDataTo(writeDataToParam), signer);
  }


}
