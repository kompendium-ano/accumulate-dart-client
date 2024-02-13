
# Unit Testing Suite for Dart Accumulate SDK

This directory contains the unit testing suite for the Dart Accumulate SDK. Our tests are primarily built using the Mockito framework and the build_runner tool to ensure high-quality and reliable code.

Suggestted Dev Dependecies include:

```bash
dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.7
  mockito: ^5.0.0
  build_runner: ^2.0.0
  ```

## Setting Up

Before executing the tests, it's essential to generate the necessary mock files. To do this, run the following command:

```bash
dart run build_runner build
```

This command prepares your `mocks.mocks.dart` file, which is crucial for the mocked tests.

## Running Tests

To execute the entire suite of unit tests, use the following command:

```bash
dart run test
```

If you wish to run a specific test file, you can do so with:

```bash
dart run test\{test file name}
```

Replace `{test file name}` with the actual name of the desired test file.

## Test Coverage

The unit tests encompass a wide range of functionalities within the Dart Accumulate SDK, including but not limited to:

- Client operations (`acc_url.dart`, `acme_client.dart`)
- API models and types (`api_types.dart`, `factom.dart`, `receipt_model.dart`, `receipt.dart`)
- Encoding and payloads (`encoding.dart`, `payload.dart`, `payload_b.dart`)
- Signature and signing operations (`signature_type.dart`, `signer.dart`, `ed25519_keypair.dart`, `ed25519_keypair_signer.dart`, `rcd1_keypair_signer.dart`)
- Transaction handling (`transaction.dart`, `tx_signer.dart`, `tx_types.dart`)
- Utility functions and operations (`utils.dart)
- RPC client and RCD signing (`rpc_client.dart`, `rcd.dart`)

By maintaining comprehensive test coverage, we aim to ensure the reliability and robustness of the Dart Accumulate SDK.

---

Please ensure to follow the setup instructions carefully to maximize the effectiveness of the test suite. 

Happy testing!