// test\rpc_client_test.dart
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'dart:convert';
import 'package:accumulate_api/src/rpc_client.dart';
import 'mocks.mocks.dart'; // Ensure this is the correct path to your generated mock file

void main() {
  group('RpcClient', () {
    late RpcClient rpcClient;
    late MockClient mockClient; // Use the generated MockClient

    setUp(() {
      mockClient = MockClient();
      rpcClient = RpcClient('http://example.com/rpc', client: mockClient);
    });

    test('RpcClient call with successful response', () async {
      final expectedResponse = {
        'jsonrpc': '2.0',
        'result': {'data': 'resultData'},
        'id': 1
      };

      when(mockClient.post(
        Uri.parse('http://example.com/rpc'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(json.encode(expectedResponse), 200));

      print('Testing RpcClient call with successful response');
      final response = await rpcClient.call('testFunction');
      print('Response: $response');
      expect(response, equals(expectedResponse));
    });

    test('RpcClient call with error response', () async {
      final expectedErrorResponse = {
        'jsonrpc': '2.0',
        'error': {'code': -32601, 'message': 'Method not found', 'data': null},
        'id': 1
      };

      when(mockClient.post(
        Uri.parse('http://example.com/rpc'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
          (_) async => http.Response(json.encode(expectedErrorResponse), 200));

      print('Testing RpcClient call with error response');
      final future = rpcClient.call('nonExistentMethod');
      await expectLater(future, throwsA(isA<RPCError>()));
    });

    test('RpcClient call with network error', () async {
      when(mockClient.post(
        Uri.parse('http://example.com/rpc'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Network error'));

      print('Testing RpcClient call with network error');
      final future = rpcClient.call('testFunction');
      await expectLater(future, throwsA(isA<Exception>()));
    });
  });
}
