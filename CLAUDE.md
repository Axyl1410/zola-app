# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get           # Install dependencies
flutter run               # Run app (hot reload enabled)
flutter analyze           # Static analysis
flutter test              # Run unit/widget tests
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<name>_test.dart  # Run integration tests
```

## Architecture

### Layered Pattern: `UI → ViewModel → Repository → Service`

**Dependency rules (enforced):**
- UI imports only ViewModel
- ViewModel imports only Repository
- Repository imports only Service
- No cross-layer imports (e.g., UI → Repository is forbidden)

### Project Structure

```
lib/
├── data/
│   ├── models/           # API models (raw server data)
│   ├── repositories/     # Data gateways, orchestrate multiple sources
│   └── services/         # I/O: HTTP, secure storage, local DB
├── domain/
│   └── models/           # Clean business objects (typed sessions, entities)
├── ui/
│   ├── core/             # Shared widgets, animations, constants
│   └── features/
│       └── <feature>/
│           ├── view_models/  # State management, business logic for UI
│           └── views/        # Widgets, screens, navigation
└── di/
    └── injector.dart     # GetIt dependency injection setup
```

### Key Patterns

**ViewModel:** Extends `ChangeNotifier`, exposes immutable state, injects Repositories via constructor.

**Repository:** Single source of truth. Maps API models → Domain models. Handles caching/offline sync.

**Service:** Stateless wrappers around external APIs (HTTP, flutter_secure_storage). No UI logic.

**DI:** GetIt-based. Register as: `LazySingleton` for Services/Repositories, `Factory` for ViewModels.

### Current Features

| Feature | Status |
|---------|--------|
| Showcase (theme/color picker) | Complete |
| Home (bottom nav: Contacts, Discover, Messages, Personal, Wall) | Complete |
| Todo (school screen) | Complete |
| Auth session (secure storage) | Complete |
| Polar/Better Auth payment flow | Documented (docs/) |

## MCP

Dart MCP server enabled via `.cursor/mcp.json` for interactive widget tree inspection and testing.

## Docs

- `docs/README-architecture-flow.md` - Full architecture spec with checklist
- `docs/README-secure-storage-session.md` - AuthSession usage
- `docs/README-polar-better-auth-mobile-flow.md` - Payment integration flow
