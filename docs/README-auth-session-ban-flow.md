# Auth Session + Ban Flow (Zola)

Tài liệu này ghi chú luồng xác thực hiện tại của app, bao gồm:

- Đăng nhập bình thường
- Kiểm tra session khi mở app / resume
- Trạng thái tài khoản bị ban
- Kiểm tra session trước thao tác quan trọng

## Trạng thái Auth

`AuthStatus` hiện có 4 trạng thái:

- `checking`
- `authenticated`
- `banned`
- `unauthenticated`

## Luồng đăng nhập Google

1. `LoginNotifier.signInWithGoogle()` gọi API `sign-in/social`.
2. Backend trả `token` + `user`.
3. `AuthStatusNotifier.markAuthenticated(token, user: user)`:
   - Lưu token vào secure storage.
   - Lưu user vào secure storage.
   - Nếu `user.banned == true` -> `AuthStatus.banned`.
   - Ngược lại -> `AuthStatus.authenticated`.

## Luồng mở app / app resume

- `main.dart` gọi:
  - `enableSessionGuard()` khi app khởi động.
  - `onAppResumed()` khi app quay lại foreground.

- `refreshAuthStatus()` dùng `ensureSessionActiveForLifecycle()` để kiểm tra:
  1. Đọc token local bằng `getValidToken()`.
  2. Nếu không có token / token hết hạn local:
     - clear session
     - `AuthStatus.unauthenticated`
  3. Nếu có token -> gọi API `get-session`.
  4. Nếu backend trả `401`:
     - logout
     - `AuthStatus.unauthenticated`
  5. Nếu backend trả user bị ban:
     - `AuthStatus.banned`
  6. Nếu backend lỗi non-401 (mạng/500...):
     - lifecycle flow giữ app tiếp tục ở trạng thái hiện tại (lenient), tránh đá user oan.

## Luồng thao tác quan trọng

Trước các action nhạy cảm (thanh toán, cập nhật dữ liệu quan trọng, thao tác cần session còn sống), gọi:

`ensureSessionActiveForCriticalAction()`

Contract:

- Trả `true` -> được phép chạy action.
- Trả `false` -> phải dừng action.
- Nếu lỗi `401` -> tự logout và về `unauthenticated`.
- Nếu lỗi non-401 -> trả `false` để chặn action, nhưng không tự đổi state về login.

## Luồng bị ban

App vào `BannedView` khi:

- Login trả về `user.banned == true`, hoặc
- `get-session` trả về `user.banned == true`.

`BannedView` hiển thị:

- Lý do ban (`banReason`, có fallback)
- Thời hạn ban (`banExpires` format `dd/MM/yyyy HH:mm`, hoặc "Ban vĩnh viễn")
- Nút liên hệ hỗ trợ / khiếu nại
- Nút đăng xuất

## Quản lý session local

Secure storage keys:

- `auth.token`
- `auth.receivedAt`
- `auth.expiresAt`
- `auth.user`

`clearSession()` sẽ xóa toàn bộ token + metadata + user cache.

## Ghi chú triển khai

- Không gọi `Repository` trực tiếp từ UI.
- UI dùng provider/view model để lấy state/user hiện tại.
- Parse lỗi backend 4xx/5xx theo format:

```json
{ "message": "..." }
```

và throw `AuthBackendHttpException`.
