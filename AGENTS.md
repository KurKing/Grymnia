# Grymnia Agent Guide

## Communication

Use `caveman` skill in full mode for this project unless user says `normal mode` or `stop caveman`.

## Product Guardrails

Grymnia is a privacy-first native iOS expense tracker for Ukrainian bank PDF statements.

Core promise:
- Import PDF statements.
- Parse transactions locally.
- Store data locally in encrypted Realm.
- Never require bank login, Open Banking, Plaid, cloud sync, account registration, backend access, or external processing of financial data.

MVP banks: Monobank and Credit Agricole.

## Current Architecture

- Native SwiftUI app with feature folders under `Grymnia/Features`.
- Parser logic lives in local Swift package `Packages/GrymniaStatementParser`.
- Parser output uses `StatementImport` and `NormalizedTransaction`.
- Storage uses Realm Swift encryption with a KeychainAccess-managed 64-byte key.
- App-level navigation uses `NavigationStack(path:)` and `AppRoute`.

Respect MVVM boundaries:
- Views: layout and user interaction.
- Store/ViewModel layer: state, task orchestration, navigation triggers.
- Services/package code: PDF extraction, parsing, storage, categorization, fingerprinting, transfer matching.

## Parser Contract

```swift
protocol BankStatementParser {
    func canParse(_ text: String) -> Bool
    func parse(_ pdf: PDFDocument) throws -> StatementImport
}
```

Keep bank quirks inside parser modules. Normalize through shared models before app/storage use.

Do not simplify duplicate detection without checking `TransactionFingerprint.make(...)` and parser tests. Fingerprint currently includes bank, account, operation/posting dates, normalized merchant/raw description, amount/currency, original amount/currency, card suffix, and occurrence index.

## Privacy Rules

Store only data needed for transaction list, analytics, account aliases, categories, dedupe, and transfer matching.

Do not store:
- full card number
- IBAN
- passport data
- address
- original PDF statement
- unrelated personal data

Keep Realm encryption through `RealmEncryptionKeyProvider`. Do not replace it with ad hoc Security framework code.

## Domain Rules

- Prefer MCC categories.
- Fallback to merchant normalization for known merchants like Silpo, Epicentr, McDonald's, OKKO, WOG, AZK.
- Mark high-confidence internal transfer matches automatically; route ambiguous matches to review.
- Preserve transaction fields already represented by `NormalizedTransaction` unless migration is intentional.

## Product Feel

Minimal, premium, privacy-focused, native Apple ecosystem. Use translucent materials, soft depth, restrained highlights, and crisp financial content.

Readability of amounts, dates, merchants, charts, and import errors wins over visual polish. Avoid generic fintech styling.

Useful copy:
- Your money. Your data.
- Private expense tracking.
- No bank login required.
- Import. Track. Done.
- Your finances stay on your iPhone.

## Testing

Use Swift Testing for domain logic. Prioritize:
- parser fixtures with redacted statements
- duplicate fingerprint stability
- merchant normalization
- category rules
- internal transfer detection
- storage encryption key lifecycle
