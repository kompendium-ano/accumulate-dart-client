// lib\src\payload\add_credits.dart

import 'dart:typed_data';
import 'package:logging/logging.dart';
import '../client/acc_url.dart';
import '../encoding.dart';
import '../client/tx_types.dart';
import '../utils/utils.dart';
import "base_payload.dart";

final Logger _logger = Logger('AddCredits');

class AddCreditsParam {
  dynamic recipient;
  dynamic amount;
  dynamic oracle;
  String? memo;
  Uint8List? metadata;
}

class AddCredits extends BasePayload {
  late AccURL _recipient;
  late int _amount;
  late int _oracle;

  AddCredits(AddCreditsParam addCreditsParam) : super() {
    _logger.info('LOG: Initializing AddCredits with parameters: '
        'recipient=${addCreditsParam.recipient}, '
        'amount=${addCreditsParam.amount}, '
        'oracle=${addCreditsParam.oracle}, '
        'memo=${addCreditsParam.memo}, '
        'metadata=${addCreditsParam.metadata != null ? "provided" : "none"}');

    _recipient = AccURL.toAccURL(addCreditsParam.recipient);
    _logger.fine('LOG: Converted recipient to AccURL: $_recipient');

    _amount = addCreditsParam.amount is int
        ? addCreditsParam.amount
        : int.parse(addCreditsParam.amount);
    _logger.fine('LOG: Parsed amount: $_amount');

    _oracle = addCreditsParam.oracle is int
        ? addCreditsParam.oracle
        : int.parse(addCreditsParam.oracle);
    _logger.fine('LOG: Parsed oracle: $_oracle');

    super.memo = addCreditsParam.memo;
    super.metadata = addCreditsParam.metadata;
    _logger.info('LOG: AddCredits instance initialized successfully.');
  }

  @override
  Uint8List extendedMarshalBinary() {
    _logger.info('LOG: Marshalling AddCredits payload to binary format.');

    List<int> forConcat = [];

    final txTypeBytes = uvarintMarshalBinaryAlt(TransactionType.addCredits, 1);
    forConcat.addAll(txTypeBytes);
    _logger.fine('LOG: Marshalled TransactionType.addCredits: ${txTypeBytes.length} bytes');

    final recipientBytes = stringMarshalBinary(_recipient.toString(), 2);
    forConcat.addAll(recipientBytes);
    _logger.fine('LOG: Marshalled recipient: ${recipientBytes.length} bytes');

    final amountBytes = bigNumberMarshalBinary(_amount, 3);
    forConcat.addAll(amountBytes);
    _logger.fine('LOG: Marshalled amount: ${amountBytes.length} bytes');

    if (_oracle > 0) {
      final oracleBytes = uvarintMarshalBinary(_oracle, 4);
      forConcat.addAll(oracleBytes);
      _logger.fine('LOG: Marshalled oracle: ${oracleBytes.length} bytes');
    }

    _logger.info('LOG: Marshalling complete. Total bytes: ${forConcat.length}');
    return forConcat.asUint8List();
  }
}
