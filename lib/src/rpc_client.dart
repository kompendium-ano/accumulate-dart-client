library json_rpc;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

class RPCError implements Exception {
  final int? errorCode;
  final String? message;
  final dynamic data;

  const RPCError(this.errorCode, this.message, this.data);

  @override
  String toString() {
    return 'RPCError: got code $errorCode with msg "$message" and data $data.';
  }
}

class RPCResponse {
  final int? id;
  final dynamic result;

  const RPCResponse(this.id, this.result);
}

class RpcClient {
  late String _endpoint;

  late int _idCounter; //Random().nextInt(5000);

  RpcClient(String endpoint) {
    _endpoint = endpoint;
    _idCounter = 0; //DateTime.now().millisecondsSinceEpoch;
  }

  Future<Map<String, dynamic>> call(String function,
      [Map<String, dynamic>? params]) async {
    params ??= {};

    Map<String, dynamic> requestPayload = {
      'jsonrpc': '2.0',
      'method': function,
      'params': params,
      'id': _idCounter++
    };

    Client client = Client();

    final response = await client.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestPayload),
    );

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final error = data['error'];

      final code = error['code'] as int?;
      final message = error['message'] as String?;
      final errorData = error['data'];
      throw RPCError(code, message, errorData);
    }

    return data;
  }
}
