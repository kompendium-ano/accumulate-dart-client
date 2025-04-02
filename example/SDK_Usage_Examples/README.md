# Accumulate SDK Examples for Dart

This repository provides a suite of examples for using the Dart SDK with the Accumulate network. These examples are designed to demonstrate the capabilities and functionalities of the Accumulate protocol, offering developers a hands-on experience to better understand how to interact with the network effectively.

The Usage Example Suite currently consists of 6 example sets:
- SDK_Examples_file_1_lite_identities.dart
- SDK_Examples_file_2_Accumulate_Identities_(ADI).dart
- SDK_Examples_file_3_ADI_Token_Accounts.dart
- SDK_Examples_file_4_Data_Accounts_and_Entries.dart
- SDK_Examples_file_5_Custom_Tokens.dart
- SDK_Examples_file_6_Key_Management.dart

## 🚀 Getting Started

To get started with these examples, ensure that Dart is installed on your system. These standalone examples demonstrate various features of the Accumulate protocol, enabling safe interactions with the blockchain through the Accumulate testnet.

Accumulate maintains multiple testnets (stable and developmental). This example suite was tested against the Accumulate Kermit testnet (stable) in February 2024, using the endpoint `https://testnet.accumulatenetwork.io/v2`.

### Prerequisites

- **Dart SDK**: Required to run the examples. If you haven't already, [install Dart](https://dart.dev/get-dart).
- **Accumulate Testnet**: The examples are configured for the Accumulate testnet environment to minimize risks while exploring the functionalities.

## 📁 Example Files Overview

Each file in the suite is designed to introduce different aspects of the Accumulate protocol.

### 1. **Lite Identities and Accounts**

**File**: `SDK_Examples_file_1_lite_identities.dart`

Lite identities serve as the entry point into the Accumulate network, offering a traditional blockchain address format. Lite identities can hold data and credits, which are used as a "gas-like" mechanism to pay for network transactions. Additionally, a lite identity can manage a lite token account for ACME tokens, the native token of the Accumulate network.

**Highlights**:
- Creation and management of Lite Identities and Accounts
- Acquiring and transferring ACME tokens
- Adding credits to Lite Token Accounts

To run Lite Identities and Accounts examples
```bash
dart run SDK_Examples_file_1_lite_identities.dart
```

### 2. **ADI Identity**

**File**: `SDK_Examples_file_2_Accumulate_Identities_(ADI).dart`

Accumulate Digital Identifiers (ADIs) are versatile and dynamic, allowing comprehensive management and authorization functionalities. ADIs can control various account types, including token accounts, data accounts, and custom tokens, offering a broad range of business and data functionalities.

**Focuses on**:
- Creation of ADI identities
- Management of key books and key pages
- Adding credits to key pages

To run ADI Identity examples
```bash
dart run SDK_Examples_file_2_Accumulate_Identities_(ADI).dart
```

### 3. **ADI Token Accounts**

**File**: `SDK_Examples_file_3_ADI_Token_Accounts.dart`

ADI Token Accounts are human-readable and controlled by an ADI's key book, facilitating ACME token transactions in a secure and efficient manner.

**Teaches**:
- Creation and management of ADI Token Accounts
- Transactions between ADI Token Accounts and Lite Token Accounts

To run ADI Token Accounts
```bash
dart run SDK_Examples_file_3_ADI_Token_Accounts.dart
```

### 4. **ADI Data Accounts**

**File**: `SDK_Examples_file_4_Data_Accounts_and_Entries.dart`

Accumulate's unique data account features enable easy data entry into the blockchain, supporting both legacy data constructs from the Factom Protocol and new scratch data entries for temporary storage.

**Covers**:
- Creation of ADI Data Accounts
- Data entry management within Data Accounts

To run Data and Lite Data Account Examples
```bash
dart run SDK_Examples_file_4_Data_Accounts_and_Entries.dart
```

### 5. **Custom Tokens**

**File**: `SDK_Examples_file_5_Custom_Tokens.dart`

Creating, issuing, and transferring custom tokens is simplified with Accumulate, requiring no smart contracts and offering flexibility for both business and personal use.

**Explores**:
- Custom token creation under an ADI
- Account management and token issuance

To run Custom Tokens Examples
```bash
dart run SDK_Examples_file_5_Custom_Tokens.dart
```

### 6. **Key Management**

**File**: `SDK_Examples_file_6_Key_Management.dart`

This example demonstrates key management functionalities essential for security and identity management within the Accumulate network.

**Explores**:
- Creation and management of Key Books and Key Pages
- Addition and updating of keys for enhanced security

To run ADI Key Management Examples
```bash
dart run SDK_Examples_file_6_Key_Management.dart
```

## 🤝 Support

For support or further clarification, consult the [Accumulate official documentation](https://docs.accumulatenetwork.io/) or join the Accumulate community on [Discord](https://discord.gg/2kBcaxrB).

## 📄 License

These examples are shared under the MIT License, encouraging open and collaborative development.
