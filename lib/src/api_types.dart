class QueryPagination {
  late int start;
  late int count;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};

    value.addAll({"start": start});
    value.addAll({"count": count});

    return value;
  }
}

class QueryOptions {
  bool? expand;
  int? height;
  bool? prove;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};

    if (expand != null) {
      value.addAll({"expand": expand!});
    }

    if (height != null) {
      value.addAll({"height": height!});
    }

    if (prove != null) {
      value.addAll({"prove": prove!});
    }

    return value;
  }
}

class TxQueryOptions extends QueryOptions {
  int? wait;
  bool? ignorePending;

  @override
  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};

    if (expand != null) {
      value.addAll({"expand": expand!});
    }

    if (height != null) {
      value.addAll({"height": height!});
    }

    if (prove != null) {
      value.addAll({"prove": prove!});
    }

    if (wait != null) {
      value.addAll({"wait": wait!});
    }

    if (ignorePending != null) {
      value.addAll({"ignorePending": ignorePending!});
    }

    return value;
  }
}

class MinorBlocksQueryOptions {
  int? txFetchMode;
  bool? filterSynthAnchorsOnlyBlocks;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};

    if (txFetchMode != null) {
      value.addAll({"txFetchMode": txFetchMode!});
    }

    if (filterSynthAnchorsOnlyBlocks != null) {
      value.addAll(
          {"filterSynthAnchorsOnlyBlocks": filterSynthAnchorsOnlyBlocks!});
    }

    return value;
  }
}

/// Options for waiting on transaction delivering.
class WaitTxOptions {
  /// Timeout after which status polling is aborted. Duration in ms.
  /// Default: 30000ms (30s)
  int timeout = 30000;

  /// Interval between each tx status poll. Duration in ms.
  /// Default: 500ms.
  int pollInterval = 500;

  /// If set to true, only the user tx status is checked.
  /// If set to false, will also wait on the associated synthetic txs to be delivered.
  /// Default: false
  bool ignoreSyntheticTxs = false;

  Map<String, dynamic> get toMap {
    Map<String, dynamic> value = {};

    value.addAll({"timeout": timeout!});

    value.addAll({"pollInterval": pollInterval!});

    value.addAll({"ignoreSyntheticTxs": ignoreSyntheticTxs!});

    return value;
  }
}

class TxError implements Exception {
  late String txId;
  dynamic status;

  TxError(String txId, dynamic status) {
    txId = txId;
    status = status;
  }

  @override
  String toString() => "Error:\ntxId:$txId\nstatus:$status";
}
