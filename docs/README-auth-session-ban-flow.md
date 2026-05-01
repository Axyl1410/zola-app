# Auth Session + Ban Flow (Zola)

Tài liệu này mô tả luồng auth hiện tại sau các refactor gần đây, bao gồm:

- Đăng nhập Google
- Kiểm tra session lúc mở app / resume
- Kiểm tra session trước thao tác quan trọng
- Xử lý người dùng bị ban
- Xử lý lỗi mạng non-401 theo hướng "chặn thao tác, không đá user ra khỏi app"

## AuthStatus hiện tại

`AuthStatus` gồm 5 trạng thái:

- `checking`
- `sessionRecoveryRequired`
- `authenticated`
- `banned`
- `unauthenticated`

Map route trong `main.dart`:

- `checking` -> loading spinner
- `sessionRecoveryRequired` -> `AuthRequiredView`
- `authenticated` -> `HomeView`
- `banned` -> `BannedView`
- `unauthenticated` -> `LoginView`

## Luồng đăng nhập Google

1. `LoginNotifier.signInWithGoogle()` gọi:
   - `GoogleAuthRepository.signInWithGoogle()`
   - `AuthBackendRepository.signInWithGoogle(...)`
2. Backend trả `token` + `user`.
3. `AuthStatusNotifier.markAuthenticated(token, user: user)`:
   - lưu session vào `AuthSessionRepository`
   - lưu/clear user cache tùy theo payload
   - nếu `user.banned == true` -> `AuthStatus.banned`
   - ngược lại -> `AuthStatus.authenticated`
4. Trong debug, token được log qua `LoginNotifier.formatTokenForLog(...)`:
   - mặc định mask token
   - có thể mở full token bằng `--dart-define=LOG_FULL_TOKEN=true` (chỉ dùng local debug)

## Luồng mở app / app resume (lifecycle)

- `main.dart` gọi:
  - `enableSessionGuard()` khi app khởi động
  - `onAppResumed()` khi app trở lại foreground

- `refreshAuthStatus()` sử dụng `validateSessionForLifecycle()` (lenient):
  1. Đọc token local bằng `getValidToken()`
  2. Nếu token thiếu/hết hạn/corrupt -> clear session, set `unauthenticated`
  3. Nếu có token -> gọi backend `getSession(...)`
  4. Nếu `401` -> clear local session, về `unauthenticated`
  5. Nếu user bị ban -> `banned`
  6. Nếu non-401/network error:
     - nếu state đang `authenticated` -> giữ `authenticated`
     - nếu state đang `banned` -> giữ `banned`
     - nếu startup đang `checking` -> đổi sang `sessionRecoveryRequired`

## Luồng thao tác quan trọng (critical action)

Trước action nhạy cảm, gọi:

- `ensureSessionActiveForCriticalAction()` hoặc
- `validateSessionForCriticalAction()`

Hành vi:

- `active` -> cho phép chạy action
- `banned` -> chặn action, không auto logout
- `unauthenticated` (thường do 401) -> logout local, về login
- `transientFailure` (non-401/network):
  - không force logout
  - chặn action hiện tại
  - UI xử lý thông báo để user thử lại

Lưu ý: critical validation có cache ngắn (`_criticalValidationCooldown = 5s`) để tránh spam backend.

## Xử lý ở màn Admin

`AdminScreen` và `AdminUsersScreen` đang dùng `validateSessionForCriticalAction()`:

- `active` + user role `admin` -> vào màn
- `active` + không phải admin -> thông báo không có quyền, quay lại
- `banned` -> dừng tại đó, không force logout
- `unauthenticated` -> logout
- `transientFailure` -> hiện SnackBar "mạng không ổn định", quay lại, không logout

## Luồng user bị ban

App vào `BannedView` khi:

- login trả user có `banned == true`, hoặc
- `getSession` trả user có `banned == true`

`BannedView` hiển thị:

- email user (nếu có)
- lý do ban (`banReason`, fallback nếu null/empty)
- thời hạn ban (`banExpires`, format `dd/MM/yyyy HH:mm`; null -> "Ban vĩnh viễn")
- nút liên hệ support/khiếu nại (mailto)
- nút đăng xuất

## Quản lý local session

Session được quản lý bởi `AuthSessionRepository` (không đặt business logic session trong `SecureStorageService` nữa).

Secure storage keys:

- `auth.token`
- `auth.receivedAt`
- `auth.expiresAt`
- `auth.user`

`clearSession()` xóa toàn bộ token + metadata + user cache.

## Auth data flow sau refactor

- `SecureStorageService`: wrapper key-value cho plugin secure storage
- `AuthSessionRepository`: chứa logic session/user (ttl, parse, expire, fail-safe clear)
- `ApiClient`: nhận `AuthTokenProvider` để lấy token, không phụ thuộc trực tiếp `AuthSessionRepository`

## Testing status (auth scope)

Auth tests đã cover:

- login success/error + token log formatting
- session save/read/expiry/corrupted storage fail-safe
- lifecycle validation + critical validation + cache reset
- route mapping theo `AuthStatus`
- banned view rendering + logout
- admin guard handling cho `active/banned/transientFailure`
