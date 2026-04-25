# Flutter Architecture Flow (Teamo)

Tai lieu nay chot luong kien truc cho codebase de de scale va giu code sach.

## Muc tieu

- Tach ro trach nhiem tung layer.
- Khoi phuc nhanh khi co bug nhung khong vo tinh pha vo UI.
- De test, de onboarding, de mo rong tinh nang.

## Luong chuan

`UI -> ViewModel -> Repository -> Service`

Du lieu tra nguoc:

`Service -> Repository -> ViewModel -> UI`

## Dinh nghia tung layer

- `UI` (`lib/ui/.../views`):
  - Render widget.
  - Bat su kien nguoi dung (tap, select, scroll).
  - Lang nghe state tu ViewModel (`Listenable`, `ChangeNotifier`, ...).
  - Khong goi truc tiep `Repository` hoac `Service`.

- `ViewModel` (`lib/ui/.../view_models`):
  - Giu state man hinh.
  - Xu ly interaction va business flow o muc UI.
  - Goi `Repository` de lay/ghi du lieu.
  - Khong goi truc tiep `Service`.

- `Repository` (`lib/data/repositories`):
  - Lam gateway du lieu cho ViewModel.
  - Dieu phoi nhieu nguon du lieu neu can (API + local cache + secure storage).
  - Map model theo nhu cau app truoc khi tra ve ViewModel.

- `Service` (`lib/data/services`):
  - I/O cu the: HTTP, secure storage, local DB, file system,...
  - Khong chua UI logic.

## Quy tac dependency (bat buoc)

- Chi cho phep:
  - `UI` import `ViewModel`
  - `ViewModel` import `Repository`
  - `Repository` import `Service`
- Cam:
  - `UI` import `Repository`/`Service`
  - `ViewModel` import `Service`
  - Import nguoc tu `data` vao `ui`

## Mapping voi codebase hien tai

- `UI`: `lib/ui/features/showcase/views/*`
- `ViewModel`: `lib/ui/features/showcase/view_models/showcase_view_model.dart`
- `Repository`:
  - `lib/data/repositories/showcase_theme_repository.dart`
  - `lib/data/repositories/auth_session_repository.dart`
- `Service`:
  - `lib/data/services/color_scheme_service.dart`
  - `lib/data/services/secure_storage_service.dart`

## Convention khi them feature moi

Tao theo khung:

- `lib/ui/features/<feature>/views/...`
- `lib/ui/features/<feature>/view_models/...`
- `lib/data/repositories/<feature>_repository.dart`
- `lib/data/services/<feature>_service.dart`

Neu flow nghiep vu lon hon, co the chen them `UseCase` giua ViewModel va Repository:

`UI -> ViewModel -> UseCase -> Repository -> Service`

## Checklist review truoc merge

- ViewModel co goi Service truc tiep khong? (khong duoc)
- UI co goi Repository/Service truc tiep khong? (khong duoc)
- Repository da gom du lieu tu cac Service can thiet chua?
- `flutter analyze` pass?
- `flutter test` pass?
