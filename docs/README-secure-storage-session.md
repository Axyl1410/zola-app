# Secure Storage + Session (Current Design)

Tài liệu này cập nhật theo design hiện tại sau refactor auth.

## Hiện trạng phân tách trách nhiệm

- `lib/data/services/secure_storage_service.dart`
  - chỉ là wrapper key-value quanh `flutter_secure_storage`
  - không chứa business logic session/user nữa
- `lib/data/repositories/auth_session_repository.dart`
  - chứa logic session auth:
    - save token/session
    - validate token còn hạn (`getValidToken`)
    - save/get/clear user cache
    - clear fail-safe khi session corrupt/expired
- `lib/domain/models/auth_session.dart`
  - model session có typed fields `token/receivedAt/expiresAt`

## Default behavior

- Secure storage defaults trên Android
- Keychain accessibility `first_unlock` trên iOS/macOS
- Session TTL mặc định ở repository: `Duration(days: 7)`

## Các key đang dùng

- `auth.token`
- `auth.receivedAt`
- `auth.expiresAt`
- `auth.user`

## Cách dùng (recommended)

Không gọi thẳng service cho auth flow. Sử dụng repository:

```dart
final repo = ref.read(authSessionRepositoryProvider);

await repo.saveToken(token);
final token = await repo.getValidToken();
final session = await repo.getSession();
await repo.clearSession();
```

Service key-value vẫn có thể dùng cho nhu cầu generic:

```dart
final storage = SecureStorageService();
await storage.writeValue(key: 'foo', value: 'bar');
final value = await storage.readValue('foo');
await storage.deleteValue('foo');
await storage.clearAll();
```

## Android note

Manifest đã cấu hình:

- `android:allowBackup="false"`

Mục tiêu: tránh backup/restore mismatch key gây lỗi encrypted storage.
