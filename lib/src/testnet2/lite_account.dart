import "dart:typed_data";
import "acc_url.dart";
import "acme.dart";
import "package:crypto/crypto.dart";
import "signer.dart" show Signer;
import "tx_signer.dart" show TxSigner;

/**
 * A LiteAccount
 */
class LiteAccount extends TxSigner {
  late AccURL _tokenUrl;
  /**
   * Construct a LiteAccount controlled by the Signer.
   * Default to ACME token if no token URL is specified.
   * 
   * 
   */



  LiteAccount(Signer signer, [dynamic tokenUrl])
      : super(LiteAccount.computeUrl(signer.publicKeyHash(), tokenUrl ? AccURL.toAccURL(tokenUrl) : ACMETokenUrl), signer) {
    final url = tokenUrl ? AccURL.toAccURL(tokenUrl) : ACMETokenUrl;


    _tokenUrl = url;
  }
  AccURL get tokenUrl => _tokenUrl;


  /**
   * Compute a LiteAccount URL based on public key hash and token URL.
   */
  static AccURL computeUrl(Uint8List publicKeyHash, AccURL tokenUrl) {
    return AccURL.parse("");
    /*
    final pkHash = Buffer.from(publicKeyHash.slice(0, 20));
    final checkSum = sha256(pkHash.toString("hex")).slice(28);
    final authority = Buffer.concat([pkHash, checkSum]).toString("hex");
    return AccURL.parse(
        '''acc://${ authority}/${ tokenUrl.authority}${ tokenUrl . path}''');*/
  }
}
