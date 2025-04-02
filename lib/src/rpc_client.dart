// lib\src\rpc_client.dart
library json_rpc;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RPCError implements Exception {
  final int? errorCode;
  final String? message;
  final dynamic data;

  RPCError(this.errorCode, this.message, this.data);

  @override
  String toString() {
    return 'RPCError: Error code $errorCode with message "$message" and data $data.';
  }
}

class RPCResponse {
  final int? id;
  final dynamic result;

  RPCResponse(this.id, this.result);
}

class RpcClient {
  final String _endpoint;
  int _idCounter = 0;
  final http.Client _client;

  RpcClient(this._endpoint, {http.Client? client})
      : _client = client ?? http.Client();

  String get endpoint => _endpoint;

  int get idCounter => _idCounter;

  Future<Map<String, dynamic>> call(String function,
      [Map<String, dynamic>? params, bool? suppressLog = false]) async {
    params ??= {};
    suppressLog ??= false;

    Map<String, dynamic> requestPayload = {
      'jsonrpc': '2.0',
      'method': function,
      'params': params,
      'id': _idCounter++,
    };

    // Log the request payload if not suppressed
    if (!suppressLog) {
      print("RPC Request Payload: ${json.encode(requestPayload)}");
    }

    try {
      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestPayload),
      );

      // Log the full HTTP response
      if (!suppressLog) {
        print("RPC Response: HTTP ${response.statusCode} ${response.body}");
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        final error = data['error'];
        final code = error['code'] as int?;
        final message = error['message'] as String?;
        final errorData = error['data'];
        print(
            "[RpcClient] Error received: Code $code, Message $message, Data $errorData");
        print(
            "[RpcClient] Request causing error: Method: $function, Params: $params, Endpoint: $_endpoint");
        throw RPCError(code, message, errorData);
      }
      return data;
    } catch (e, stackTrace) {
      print("[RpcClient] Exception occurred: $e");
      print(stackTrace);
      rethrow;
    }
  }
}