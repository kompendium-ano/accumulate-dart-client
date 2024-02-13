
# Accumulate Dart SDK


[![Pub Version](https://img.shields.io/pub/v/accumulate_api)](https://pub.dev/packages/accumulate_api)
[![GitHub License](https://img.shields.io/github/license/kompendium-ano/accumulate-dart-client)](LICENSE)
[![Build Status](https://github.com/kompendium-ano/accumulate-dart-client/actions/workflows/dart.yml/badge.svg)](https://github.com/kompendium-ano/accumulate-dart-client/actions/workflows/dart.yml)

The Dart SDK for the Accumulate blockchain provides developers with the tools needed to interact with the Accumulate network. This SDK supports all Accumulate API classes, basic data types, and utility functions for creating specific requests, aiming to simplify the development process for applications leveraging the Accumulate blockchain's scalable and secure infrastructure.

The Accumulate Dart SDK repositiory is organized with three main strucutres:
 - Client library: [lib](/lib/src/src/)
 - Test Stuite: [tests](/test/README.md/)
 - Accumulate Usage Examples Collection: [examples](/examples/SDK_Usage_Examples/README.md/)  

## Installation

### Dart

```bash
dart pub add accumulate_api
```

This adds `accumulate_api` to your package's `pubspec.yaml` file and runs an implicit `dart pub get`.

### Flutter

```bash
flutter pub add accumulate_api
```

For both Dart and Flutter, ensure your `pubspec.yaml` reflects the correct dependency:

```yaml
dependencies:
  accumulate_api: ^version
```

Replace `^version` with the latest version of `accumulate_api`.

### Import the SDK

In your Dart code, import the package with:

```dart
import 'package:accumulate_api/accumulate_api.dart';
```

## Practical Usage Examples

The Accumulate Dart SDK enables you to access nearly all the features and fucnitonality that accumualte offers.
Explore practical examples in the [Examples](/examples/SDK_Usage_Examples/) section to start building with the Accumulate Dart SDK. This repository provides a suite of examples designed to demonstrate the capabilities and functionalities of the Accumulate protocol, offering developers a hands-on experience to better understand how to interact with the network effectively.

The Usage Example Suite currently consists of 6 collections of example sets:
### 1. Lite Identities and Lite Token Accounts
- Create/manage Lite Identities/Accounts for ACME tokens
- Acquire testnet ACME tokens via faucet
- Add credits to Lite Identities
- Create Lite Token Accounts for ACME
- Transfer ACME tokens between Lite Accounts

### 2. Accumulate Digital Identifier (ADI)
- Create ADI Identity
- Add credits to Key Page

### 3. ADI Token Accounts
- Create ADI Token Accounts for ACME
- Transfer ACME tokens between ADI Accounts and to Lite Accounts

### 4. ADI Data Accounts
- Create/manage ADI Data Accounts
- Write/manage data entries
- Utilize scratch data entries and lite data accounts

### 5. Custom Tokens
- Create custom tokens under ADI
- Create custom token accounts and issue tokens
- Transfer custom tokens between ADI Custom Token Accounts

### 6. Key Management
- Manage keys for security/identity (ADI)
- Create/additional/custom Key Books/Pages
- Update Key Page (add keys)


## Contributions

We welcome contributions from the community. To contribute, please submit a pull request or open an issue for discussion.

### Maintainers

- Sergey Bushnyak (sergey.bushnyak@kelecorix.com)
- Jimmy Jose (theguywhomakesapp@gmail.com)
- Jason Gregoire (jason@kompendiumllc.co)

This library is developed by Kompendium, LLC in partnership with Kelecorix, Inc, and individual contributors like Sergey Bushnyak. Your contributions and feedback are welcome.

## License

This project is licensed under the [MIT License](LICENSE).