import 'dart:convert';
import 'dart:typed_data';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

String privateKeyToHex(dynamic privateKey) {
  Uint8List keyBytes;

  // Check if the privateKey is a string (e.g., a base64-encoded or plain string)
  if (privateKey is String) {
    try {
      // Try decoding it as Base64 first
      keyBytes = base64Decode(privateKey);
    } catch (e) {
      // If not Base64, assume it's a raw string and convert to bytes
      keyBytes = Uint8List.fromList(utf8.encode(privateKey));
    }
  } 
  // Check if the privateKey is already Uint8List
  else if (privateKey is Uint8List) {
    keyBytes = privateKey;
  } 
  // Unsupported type
  else {
    throw ArgumentError("Unsupported key format. Provide a String or Uint8List.");
  }

  return _toHex(keyBytes);
}

String publicKeyFromPrivateKey(dynamic privateKey) {
  Uint8List keyBytes;

  // Convert private key into Uint8List
  if (privateKey is String) {
    try {
      keyBytes = base64Decode(privateKey);
    } catch (e) {
      keyBytes = Uint8List.fromList(utf8.encode(privateKey));
    }
  } else if (privateKey is Uint8List) {
    keyBytes = privateKey;
  } else {
    throw ArgumentError("Unsupported key format. Provide a String or Uint8List.");
  }

  // Ensure the keyBytes is 32 bytes (seed-only format) or truncate to 32 bytes
  if (keyBytes.length < 32) {
    throw ArgumentError("Invalid private key length. Expected at least 32 bytes.");
  }
  keyBytes = keyBytes.sublist(0, 32);

  // Derive public key
  final ed.PrivateKey privateKeyObj = ed.PrivateKey(keyBytes);
  final ed.PublicKey publicKeyObj = ed.public(privateKeyObj);

  // Convert publicKeyObj.bytes to Uint8List explicitly
  Uint8List publicKeyBytes = Uint8List.fromList(publicKeyObj.bytes);

  return _toHex(publicKeyBytes);
}

String _toHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}

void main() {
  // Example private key in string format (replace with your actual key)
  String exampleKey = "private_key_here";

  try {
    // Convert private key to Hex
    String hexPrivateKey = privateKeyToHex(exampleKey);
    print("Hexadecimal Private Key: $hexPrivateKey");

    // Derive public key from private key
    String publicKey = publicKeyFromPrivateKey(exampleKey);
    print("Derived Public Key (Hex): $publicKey");
  } catch (e) {
    print("Error: ${e.toString()}");
  }
}
