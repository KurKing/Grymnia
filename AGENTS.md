# Grymnia Agent Guide

## Communication

Always use `caveman` skill in full mode for this project unless the user explicitly says `normal mode` or `stop caveman`.

## Product

Grymnia is a privacy-first native iOS expense tracker for Ukrainian bank PDF statements.

MVP banks:
- Monobank
- Credit Agricole

Core promise:
- Import PDF statements.
- Parse transactions locally.
- Store data locally in encrypted storage.
- Never require bank login, Open Banking, Plaid, cloud sync, account registration, backend access, or external processing of financial data.

## Stack

- SwiftUI
- MVVM
- NavigationStack with path-based navigation
- PDFKit for statement text extraction
- Realm Swift with AES-256 encryption
- KeychainAccess for the 64-byte Realm encryption key
- LocalAuthentication for optional app lock
- Charts for analytics
- Swift Concurrency for import/parsing work

## Architecture

Prefer feature-oriented folders:

```text
Grymnia/
  App/
  Core/
    Models/
    Storage/
    Security/
    Navigation/
  Features/
    Import/
    Transactions/
    Analytics/
    Settings/
  Parsers/
    Shared/
    Monobank/
    CreditAgricole/
```

Use MVVM boundaries:
- `View`: layout and user interaction only.
- `ViewModel`: screen state, validation, task orchestration, navigation intents.
- `Service`: PDF extraction, parsing, storage, categorization, fingerprinting.
- `Model`: domain data and persistence mapping.

Navigation:
- Use `NavigationStack(path: $router.path)`.
- Use `enum AppRoute: Hashable`.
- Inject shared router/app navigation through environment.
- Avoid scattered `NavigationLink(destination:)` for app-level flows.

Parser contract:

```swift
protocol BankStatementParser {
    func canParse(_ text: String) -> Bool
    func parse(_ pdf: PDFDocument) throws -> StatementImport
}
```

Keep parser output normalized through one internal model. Keep bank quirks inside parser modules.

## Privacy

Store only:
- transactions
- merchant
- category
- amount
- account alias
- bank
- card suffix
- import fingerprint

Do not store:
- full card number
- IBAN
- passport data
- address
- original PDF statement
- unrelated personal data

Use Realm encryption with the KeychainAccess-managed 64-byte key. Do not write an ad hoc Security framework wrapper.

## Domain Rules

Transaction fields should support:
- id
- bank
- accountID
- cardSuffix
- operationDate
- postingDate
- merchant
- rawDescription
- MCC
- amount
- currency
- originalAmount
- originalCurrency
- exchangeRate
- cashback
- fee
- balanceAfter
- type

Duplicate fingerprint:

```text
SHA256(bank + accountID + operationDate + normalizedMerchant + amount + currency)
```

Merge matching outgoing/incoming transfers across accounts or banks into one `Internal Transfer`.

Prefer MCC categories. Fallback to merchant normalization:
- `SILPO`, `SILPO MARKET`, `SILPO #123` -> `Silpo`
- `EPITCENTR`, `SHOP EPITSENTR` -> `Epicentr`

## Product Feel

Feel: minimal, premium, privacy-focused, native Apple ecosystem, Liquid Glass-inspired where platform APIs support it.

Avoid generic fintech styling. Use translucent materials, soft depth, restrained highlights, and crisp financial content. Readability of amounts, dates, merchants, charts, and import errors wins over visual polish.

Useful taglines:
- Your money. Your data.
- Private expense tracking.
- No bank login required.
- Import. Track. Done.
- Your finances stay on your iPhone.

App Store naming direction:
- `Grymnia - Private Expense Tracker`
- `Grymnia - Offline Budget`

## Testing

Use Swift Testing for domain logic. Prioritize:
- parser fixtures with redacted statements
- duplicate fingerprint stability
- merchant normalization
- category rules
- internal transfer detection
- storage encryption key lifecycle
