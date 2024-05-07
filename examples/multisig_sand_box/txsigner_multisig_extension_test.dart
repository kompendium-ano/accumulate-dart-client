// examples\multisig_sand_box\txsigner_multisig_extension_test.dart


import 'package:accumulate_api/src/client/acc_url.dart';
import 'package:accumulate_api/src/client/tx_signer.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair_signer.dart';
import 'package:accumulate_api/src/signing/ed25519_keypair.dart';
import 'package:convert/convert.dart';

void main() {
  var keypair = Ed25519Keypair.generate();
  var signer =
      Ed25519KeypairSigner(keypair);

  var url = AccURL(
      'acc://custom-adi-name-1714297678838.acme/data-account');
  var txSigner = TxSigner(url, signer);

  String txHash =
      "a11a8158f7d20ec580a453f7bdeb89bad610d9ae15a9be8dcd8f0bfbe14629e5";

  var signature = txSigner.signMultisigTransaction(txHash);

  String signatureHex = signature.signature != null
      ? hex.encode(signature.signature!)
      : 'No signature available';

  // Output the results
  print("Signature: ${signature.signature}");
  print("Signer Info: ${signature.signerInfo}");
  print("SignatureHex: $signatureHex");
}
