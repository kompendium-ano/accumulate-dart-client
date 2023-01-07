# Feature Focused Examples

Collection of examples that tests specific feaure and cointains minimal set of steps to prepare for this
feature correct execution.

| N   | File                                 | Description                                             |   
|-----|--------------------------------------|---------------------------------------------------------|
| 1   | create_adi.dart                      | workflow for creating ADI                               |  
| 2   | create_acc_data_light_from_adi.dart  | workflow for creating Lite Data Account from Adi        |   
| 3   | create_acc_data_light_from_lite.dart | workflow for creating Lite Data Account from Lite Token |  
| 4   | create_acc_token.dart                | workflow for creating Custom Toke, Custom Token Account |  
| 5   | crud_authority.dart                  | CRUD actions for authority  


// data is List<Uint8List> which is collection of entries
//
Uint8List marshalDataEntries(List<Uint8List> data) {
List<int> forConcat = [];

    // AccumulateDataEntry DataEntryType 2
    //forConcat.addAll(uvarintMarshalBinary(2, 1));

    int dataEntryType = 2; // Accumulate
    //forConcat.addAll(uvarintMarshalBinary(dataEntryType, 1));

    // Data
    List<int> temp = [];
    for (Uint8List dataEntry in data) {
      forConcat.addAll(uvarintMarshalBinary(dataEntryType, 1));
      temp.addAll(bytesMarshalBinary(dataEntry, 2));
    }

    forConcat.addAll(temp);


    return bytesMarshalBinary(forConcat.asUint8List());
}|  