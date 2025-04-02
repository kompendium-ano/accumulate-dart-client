import 'package:test/test.dart';
import 'package:accumulate_api/accumulate_api.dart';
import 'package:accumulate_api/src/model/receipt_model.dart';

void main() {
  group('ReceiptModel', () {
    test('ReceiptModel fromMap() and toMap()', () {
      final receiptModel = ReceiptModel(
        jsonrpc: '2.0',
        result: ReceiptModelResult(
          type: 'exampleType',
          mainChain: MainChain(roots: ['root1', 'root2']),
          merkleState: MainChain(roots: ['merkleRoot1', 'merkleRoot2']),
          data: RcpData(
            type: 'dataType',
            url: 'dataUrl',
            symbol: 'dataSymbol',
            precision: 2,
          ),
          origin: 'exampleOrigin',
          sponsor: 'exampleSponsor',
          transactionHash: 'txHash123',
          txid: 'txid123',
          transaction: RcpTransaction(
            header: RcpHeader(
              principal: 'principal123',
              initiator: 'initiator123',
            ),
            body: RcpData(
              type: 'transactionType',
              url: 'transactionUrl',
              symbol: 'transactionSymbol',
              precision: 3,
            ),
          ),
          signatures: [
            RcpSignature(
              type: 'signatureType',
              publicKey: 'publicKey123',
              signature: 'signature123',
              signer: 'signer123',
              signerVersion: 1,
              timestamp: 1234567890,
              transactionHash: 'txHash123',
            ),
          ],
          status: Status(
            txId: 'txId123',
            code: 'code123',
            delivered: true,
            codeNum: 123,
            result: StatusResult(type: 'statusType'),
            received: 987654321,
            initiator: 'initiator123',
            signers: [
              SignerElement(
                type: 'signerType',
                keyBook: 'keyBook123',
                url: 'url123',
                acceptThreshold: 2,
                threshold: 3,
                version: 1,
              ),
            ],
          ),
          receipts: [
            Receipts(
              localBlock: 456,
              proof: Proof(
                start: 'start123',
                startIndex: 0,
                end: 'end123',
                endIndex: 1,
                anchor: 'anchor123',
                entries: [
                  ReceiptEntry(hash: 'hash1', right: true),
                  ReceiptEntry(hash: 'hash2', right: false),
                ],
              ),
              receipt: Proof(
                start: 'receiptStart123',
                startIndex: 2,
                end: 'receiptEnd123',
                endIndex: 3,
                anchor: 'receiptAnchor123',
                entries: [
                  ReceiptEntry(hash: 'receiptHash1', right: true),
                  ReceiptEntry(hash: 'receiptHash2', right: false),
                ],
              ),
              account: 'account123',
              chain: 'chain123',
            ),
          ],
          signatureBooks: [
            SignatureBook(
              authority: 'authority123',
              pages: [
                Page(
                  signer: PageSigner(
                    type: 'pageSignerType',
                    url: 'pageSignerUrl',
                    acceptThreshold: 2,
                  ),
                  signatures: [
                    RcpSignature(
                      type: 'pageSignatureType',
                      publicKey: 'pagePublicKey123',
                      signature: 'pageSignature123',
                      signer: 'pageSigner123',
                      signerVersion: 1,
                      timestamp: 1234567890,
                      transactionHash: 'pageTxHash123',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        id: 1,
      );

      final map = receiptModel.toMap();
      final decodedReceiptModel = ReceiptModel.fromMap(map);
      final originalJson = receiptModelToMap(receiptModel);
      final decodedJson = receiptModelToMap(decodedReceiptModel);

      // Compare JSON strings to ensure the content is identical
      expect(decodedJson, equals(originalJson));
    });
  });
}
