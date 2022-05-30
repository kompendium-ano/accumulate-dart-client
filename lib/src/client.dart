import "dart:async";
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:hex/hex.dart';

import "acc_url.dart" show AccURL;
import "acme.dart";
import "api_types.dart"
    show
        MinorBlocksQueryOptions,
        QueryOptions,
        QueryPagination,
        TxError,
        TxQueryOptions,
        WaitTxOptions;
import "payload.dart" show Payload;
import "payload/add_credits.dart" show AddCredits, AddCreditsArg;
import "payload/add_validator.dart" show AddValidator, AddValidatorArg;
import "payload/burn_tokens.dart" show BurnTokens, BurnTokensArg;
import "payload/create_data_account.dart"
    show CreateDataAccount, CreateDataAccountArg;
import "payload/create_identity.dart" show CreateIdentity, CreateIdentityArg;
import "payload/create_key_book.dart" show CreateKeyBook, CreateKeyBookArg;
import "payload/create_key_page.dart" show CreateKeyPage, CreateKeyPageArg;
import "payload/create_token.dart" show CreateToken, CreateTokenArg;
import "payload/create_token_account.dart"
    show CreateTokenAccount, CreateTokenAccountArg;
import "payload/issue_tokens.dart" show IssueTokens, IssueTokensArg;
import "payload/remove_validator.dart" show RemoveValidator, RemoveValidatorArg;
import "payload/send_tokens.dart" show SendTokens, SendTokensArg;
//import "payload/update_account_auth.dart" show AccountAuthOperation, UpdateAccountAuth;
import "payload/update_key.dart" show UpdateKey, UpdateKeyArg;
//import "payload/update_key_page.dart" show KeyPageOperation, UpdateKeyPage;
import "payload/update_validator_key.dart"
    show UpdateValidatorKey, UpdateValidatorKeyArg;
import "payload/write_data.dart" show WriteData, WriteDataArg;
import "rpc_client.dart" show RpcClient;
import "transaction.dart" show Header, Transaction;
import "tx_signer.dart" show TxSigner;
import "utils.dart" show sleep;

class Client {
  late RpcClient _rpcClient;

  Client(String endpoint) {
    _rpcClient = RpcClient(endpoint);
  }

  Future<Map<String, dynamic>> call(String method,
      [Map<String, dynamic>? params]) {
    return _rpcClient.call(method, params);
  }

  Future<Map<String, dynamic>> _execute(
      AccURL principal, Payload payload, TxSigner signer) async {
    final header = Header(principal);
    final tx = Transaction(payload, header);
    await tx.sign(signer);

    return execute(tx);
  }

  Future<Map<String, dynamic>> execute(Transaction tx) {
    return call("create-adi", tx.toTxRequest().toMap);
    //return call("execute", tx.toTxRequest().toMap);
  }

  Future<Map<String, dynamic>> queryAcmeOracle() {
    return queryData(ACMEOracleUrl);
  }

  Future<Map<String, dynamic>> queryData(dynamic url, [String? entryHash]) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    if (entryHash != null && entryHash!.isNotEmpty) {
      params.addAll({"entryHash": entryHash});
    }
    return call("query-data", params);
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
    Map<String, dynamic> params = {};
    params.addAll({"txid": txId});
    if (options != null) {
      params.addAll(options.toMap);
    }

    return call("query-tx", params);
  }

  Future<Map<String, dynamic>> queryTxHistory(
      dynamic url, QueryPagination pagination) {
    Map<String, dynamic> params = {};
    params.addAll({"url": url.toString()});
    params.addAll(pagination.toMap);
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

  /**
   * Wait for a transaction (and its associated synthetic tx ids) to be delivered.
   * Throw an error if the transaction has failed or the timeout is exhausted.
   * @param txId
   * @param options
   * @returns void
   */
  Future<void> waitOnTx(String txId, [WaitTxOptions? options]) async {
    Completer completer = Completer();
    // Options
    final to = options?.timeout ?? 30000;
    final pollInterval = options?.pollInterval ?? 500;
    final ignoreSyntheticTxs = options?.ignoreSyntheticTxs ?? false;



    final start = DateTime.now().millisecondsSinceEpoch;
    dynamic lastError;
    do {
      try {
        final resp = await queryTx(txId);
        Map<String,dynamic> result = resp["result"];

        log("wait on tx resp ${jsonEncode(resp["result"]["syntheticTxids"])}");
        List<String> syntheticTxids = [];//resp["result"]["syntheticTxids"];
        Map<String, dynamic> status = {};
        if(result.containsKey("syntheticTxids")){
          syntheticTxids = List<String>.from(result["syntheticTxids"]);
          log("wait on tx resp ${jsonEncode(syntheticTxids)}");
        }

        if(result.containsKey("status")){
          status = result["status"];
          log("wait on tx resp ${jsonEncode(status)}");
        }




        if (!status.containsKey("delivered")) {
          throw Exception("Transaction not delivered");
        }else{
          bool delivered = status["delivered"] as bool;
          print(delivered);
          if(delivered){
           return completer.complete();
          }
        }

        if (status.containsKey("code")) {
          throw TxError(txId, status);
        }

        if (ignoreSyntheticTxs) {
          return;
        }

        // Also verify the associated synthetic txs
        final timeoutLeft = to - DateTime.now().millisecondsSinceEpoch + start;
        final List<String> stxIds = [];
        if (syntheticTxids.isNotEmpty) {
          stxIds.addAll(syntheticTxids);
        }

        WaitTxOptions waitTxOptions = WaitTxOptions();
        waitTxOptions.timeout = timeoutLeft;
        waitTxOptions.pollInterval = options?.pollInterval;
        waitTxOptions.ignoreSyntheticTxs = options?.ignoreSyntheticTxs;

        for(String stxId in stxIds) {
          await waitOnTx(stxId, waitTxOptions);
        }

        /*
        await Future.forEach(
            stxIds, (stxId) => waitOnTx(stxId as String, waitTxOptions));*/

        return completer.future;
      } catch (e) {
        // Do not retry on definitive transaction errors
        if (e is TxError) {
          rethrow;
        }

        lastError = e;
        sleep(Duration(milliseconds: pollInterval));
      }
      // Poll while timeout is not reached
    } while (DateTime.now().millisecondsSinceEpoch - start < to);

    return completer.complete();
    throw Exception(
        'Transaction $txId was not confirmed within ${to / 1000}s. Cause: $lastError');
  }

  Future<Map<String, dynamic>> addCredits(
      dynamic principal, AddCreditsArg addCredits, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), AddCredits(addCredits), signer);
  }

  Future<Map<String, dynamic>> addValidator(
      dynamic principal, AddValidatorArg addValidator, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), AddValidator(addValidator), signer);
  }

  Future<Map<String, dynamic>> burnTokens(
      dynamic principal, BurnTokensArg burnTokens, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), BurnTokens(burnTokens), signer);
  }

  Future<Map<String, dynamic>> createDataAccount(dynamic principal,
      CreateDataAccountArg createDataAccount, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateDataAccount(createDataAccount), signer);
  }

  Future<Map<String, dynamic>> createIdentity(
      dynamic principal, CreateIdentityArg createIdentity, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateIdentity(createIdentity), signer);
  }

  Future<Map<String, dynamic>> createKeyBook(
      dynamic principal, CreateKeyBookArg createKeyBook, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateKeyBook(createKeyBook), signer);
  }

  Future<Map<String, dynamic>> createKeyPage(
      dynamic principal, CreateKeyPageArg createKeyPage, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateKeyPage(createKeyPage), signer);
  }

  Future<Map<String, dynamic>> createToken(
      dynamic principal, CreateTokenArg createToken, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), CreateToken(createToken), signer);
  }

  Future<Map<String, dynamic>> createTokenAccount(dynamic principal,
      CreateTokenAccountArg createTokenAccount, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        CreateTokenAccount(createTokenAccount), signer);
  }

  Future<Map<String, dynamic>> issueTokens(
      dynamic principal, IssueTokensArg issueTokens, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), IssueTokens(issueTokens), signer);
  }

  Future<Map<String, dynamic>> removeValidator(
      dynamic principal, RemoveValidatorArg removeValidator, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), RemoveValidator(removeValidator), signer);
  }

  Future<Map<String, dynamic>> sendTokens(
      dynamic principal, SendTokensArg sendTokens, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), SendTokens(sendTokens), signer);
  }

  /*
  Future<Map<String, dynamic>> updateAccountAuth(dynamic principal,
      List<AccountAuthOperation> operation, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), UpdateAccountAuth(operation), signer);
  }
*/
  Future<Map<String, dynamic>> updateKey(
      dynamic principal, UpdateKeyArg updateKey, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal), UpdateKey(updateKey), signer);
  }
/*
  Future<Map<String, dynamic>> updateKeyPage(
      dynamic principal, List<KeyPageOperation> operation, TxSigner signer) {
    return _execute(
        AccURL.toAccURL(principal), UpdateKeyPage(operation), signer);
  }*/

  Future<Map<String, dynamic>> updateValidatorKey(dynamic principal,
      UpdateValidatorKeyArg updateValidatorKey, TxSigner signer) {
    return _execute(AccURL.toAccURL(principal),
        UpdateValidatorKey(updateValidatorKey), signer);
  }

  Future<Map<String, dynamic>> writeData(
      dynamic principal, WriteDataArg writeData, TxSigner signer) {
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
}
