# Secure Storage Session Utils

Utility added for managing auth token/session in a scalable structure:

- `lib/data/services/secure_storage_service.dart`
- `lib/domain/models/auth_session.dart`

## Why this structure

Following layered architecture:

- Data layer service wraps platform plugin (`flutter_secure_storage`).
- Domain model (`AuthSession`) gives typed session object for app logic.

## Default behavior

- Uses secure storage defaults on Android (latest plugin cipher backend).
- Uses Keychain accessibility on iOS/macOS (`first_unlock`).
- Session TTL defaults to 7 days (`Duration(days: 7)`).

## Basic usage

```dart
final storage = SecureStorageService();

// Save token with default 7 days TTL
await storage.saveSessionToken(tokenFromBackend);

// Read valid token (returns null if expired/missing)
final token = await storage.getValidToken();

// Read full session metadata
final session = await storage.getSession();

// Clear only auth session keys
await storage.clearSession();
```

## Generic key-value helpers

```dart
await storage.writeValue(key: 'foo', value: 'bar');
final value = await storage.readValue('foo');
await storage.deleteValue('foo');
await storage.clearAll();
```

## Android note

Manifest configured with:

- `android:allowBackup="false"`

This avoids backup/restore key mismatch issues that can break encrypted storage.
