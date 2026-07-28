# Grymnia

Privacy-first expense tracker for Ukrainian banks.

Grymnia imports bank statements, parses transactions locally, and keeps financial data on device. No bank login, no Open Banking, no backend, no account registration.

## MVP

- PDF statement import via PDFKit
- Local parsing into normalized transactions
- Encrypted on-device storage
- Optional Face ID, Touch ID, or device passcode lock
- Initial bank support: Monobank and Credit Agricole

## Privacy

Data flow:

```text
PDF Statement
PDFKit Parser
Normalized Transactions
Encrypted Realm
Charts & Analytics
```

Store only transaction data needed for analytics. Do not store full card numbers, IBANs, passport data, addresses, original PDF statements, or unrelated personal information.

## Parser Direction

Each bank parser outputs the same normalized import model. Bank-specific quirks stay inside parser modules.

## Product Direction

Grymnia should feel minimal, premium, private, and native to Apple platforms.

Tagline direction:

> Your money. Your data.
