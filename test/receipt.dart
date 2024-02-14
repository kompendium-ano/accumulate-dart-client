import 'package:accumulate_api/accumulate_api.dart';
import 'package:test/test.dart';
import 'package:hex/hex.dart';
void main() {
  test('should clone receipt with string hashes', () {

    Receipt r1 = Receipt()
      ..start = "c5f890fa64b1321b8454a53c4106faca35f7acf4f8e535e28153d11460885a52"
      ..startIndex = 1
      ..end = "c5f890fa64b1321b8454a53c4106faca35f7acf4f8e535e28153d11460885a52" //body.hash()
      ..endIndex = 1
      ..anchor = "ceb7ad426ca0e66dc4aef2002c92de6172d452f7e181279246205caea32962ca" //txn.hash()
      ..entries = [
        ReceiptEntry()..hash = "baee50fcd5b881c14fd54437d5b371cadedc0bce12f3f443e42a91529005c588",
        ReceiptEntry()
          ..hash = "d52ff6d28d5ae24afa5b07792ac5b9b41ac901bdf6878fc0f3575ca939e455b1"
          ..right = true,
      ];

    var r2 = cloneReceipt(r1);

    // Check the clone has equal fields
    expect(r1.start, r2.start);
    expect(r1.startIndex, r2.startIndex);
    expect(r1.end, r2.end);
    expect(r1.endIndex, r2.endIndex);
    expect(r1.anchor, r2.anchor);
    expect(r1.entries.length, r2.entries.length);

    // assert entries


  });

  test('should combine receipts', () async {
    Receipt r1 = Receipt()
      ..start = "c5f890fa64b1321b8454a53c4106faca35f7acf4f8e535e28153d11460885a52" //body.hash()
      ..startIndex = 1
      ..end = "c5f890fa64b1321b8454a53c4106faca35f7acf4f8e535e28153d11460885a52" //body.hash()
      ..endIndex = 1
      ..anchor = "ceb7ad426ca0e66dc4aef2002c92de6172d452f7e181279246205caea32962ca" //txn.hash()
      ..entries = [
        ReceiptEntry()..hash = "baee50fcd5b881c14fd54437d5b371cadedc0bce12f3f443e42a91529005c588",
        ReceiptEntry()..hash = "d52ff6d28d5ae24afa5b07792ac5b9b41ac901bdf6878fc0f3575ca939e455b1",
        ReceiptEntry()..hash = "11e5067b046acd688a1ee4457e9792ea236e3f7a429b49d73c418fe86cccd8cd",
        ReceiptEntry()..hash = "bd09e34a5699ce91c9ad35333e4e65a875de7c3353975a5f644fcb24483a6257",
        ReceiptEntry()..hash = "4a516cec8fa0cff2a46097fa8fe16fe31a281f1c1cfaeb413d0acb6be95d8bc1",
        ReceiptEntry()..hash = "3b95c9a7de9bc5dde675dea63dabbaef089b9ee21868cd84f3c0277d2507c5a2",
      ];

    Receipt r2 = Receipt()
      ..start = "ceb7ad426ca0e66dc4aef2002c92de6172d452f7e181279246205caea32962ca" //body.hash()
      ..startIndex = 32
      ..end = "ceb7ad426ca0e66dc4aef2002c92de6172d452f7e181279246205caea32962ca" //body.hash()
      ..endIndex = 32
      ..anchor = "e256404fca6505e7663b1ad0490a13beb0e89d2c315b10b915f607760831560c" //txn.hash()
      ..entries = [
        ReceiptEntry()..hash = "7cdf9cf3825c367017d2744860bb20bc01af62299e90f56599d34c99ce081dfc",
        ReceiptEntry()..hash = "bd91711895d09a793a60c92cc895c0c97c549c1764dae887ce8e9ec9fdc530f1",
        ReceiptEntry()
          ..hash = "154ff546f3937121bb79907a9fce706003bfc6f8dd48aca64a779e59e9ffe990"
          ..right = true,
        ReceiptEntry()..hash = "232fe211abeb588bd413e0ef97fff351d1a052fdc89f90b67dabf32a21c4964d",
        ReceiptEntry()..hash = "4461bde50ac321d849a6ad10aa9593339c16cb6eda46e296f561a19893cc0f1a",
        ReceiptEntry()..hash = "06ba0d8adcd7b0fb16508f09b5f644c63010791cb1ce4f186d4b3e951305ca24",
        ReceiptEntry()..hash = "cea9ddc3f85f2336e881f32160dbb5f4da5881494bee4a99836a7089e4cebf48",
      ];

    var combined = combineReceipts(r1, r2);

    // check assertions
    expect(r1.entries.length, 6);
    expect(r2.entries.length, 7);
    expect(combined.entries.length, r1.entries.length + r2.entries.length);
    expect(combined.anchor, r2.anchor);
  });

  test('should construct proper proof', () async {

    final acmeClient = ACMEClient("https://testnet.accumulatenetwork.io" + "/v2");

    var tokenUrl = "acc://adi-cosmonaut-1683381203133.acme/cosmos";

    var proof = await constructIssuerProof(acmeClient, tokenUrl);

    var receiptFinal = proof.value1;

    print(HEX.encode(receiptFinal.start));
    print(HEX.encode(receiptFinal.end));
    print(HEX.encode(receiptFinal.anchor));
    print(receiptFinal.entries.length);

    for(ReceiptEntry rcpe in receiptFinal.entries){
      print(HEX.encode(rcpe.hash) + " | " + rcpe.right.toString());
    }

    // check our assumptions, resulted values are taken from JS library for comparison
    expect(HEX.encode(receiptFinal.start) , "000a7a81e423d825bf5f1ecca0b06d28292fa1563335356febeddaae6fcf1c06");
    expect(HEX.encode(receiptFinal.end)   , "000a7a81e423d825bf5f1ecca0b06d28292fa1563335356febeddaae6fcf1c06");
    expect(HEX.encode(receiptFinal.anchor), "9f29581715bd9a99f50d5d0b9696ab8c241f9c5b2c62136beb5d1a87fd9c27a6");

  });
}
