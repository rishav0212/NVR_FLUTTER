# Sentinel — Flutter Project Structure Guide

### A complete reference for every file, its purpose, and where to make changes

---

## The Big Picture — How a Flutter App Works

Before individual files, understand the 3-layer mental model:

```
┌─────────────────────────────────────────────────────────┐
│  UI LAYER  — What the user sees (Pages, Widgets)        │
│             Reads state, dispatches events              │
├─────────────────────────────────────────────────────────┤
│  LOGIC LAYER — BLoC (Business Logic Component)          │
│                Receives events, calls repository,       │
│                emits new states                         │
├─────────────────────────────────────────────────────────┤
│  DATA LAYER — Repository + ApiClient                    │
│               Makes HTTP calls, stores tokens,          │
│               returns models                            │
└─────────────────────────────────────────────────────────┘
```

**One-way data flow:**

```
User taps button
     ↓
Page dispatches Event  (e.g. LoginRequested)
     ↓
BLoC receives Event, calls Repository
     ↓
Repository makes HTTP call, returns Model
     ↓
BLoC emits new State  (e.g. AuthAuthenticated)
     ↓
Page rebuilds with new State → Router redirects
```

---

## Full File Map

```
android/                          ← Android-specific native config
lib/                              ← ALL your Flutter/Dart code lives here
├── main.dart                     ← App entry point
├── injection_container.dart      ← Dependency injection (GetIt)
│
├── core/                         ← Shared infrastructure (not feature-specific)
│   ├── constants/
│   │   └── app_constants.dart    ← All string constants (URLs, routes, keys)
│   ├── network/
│   │   └── api_client.dart       ← HTTP client (Dio) + auth interceptor
│   ├── router/
│   │   └── app_router.dart       ← Navigation (GoRouter) + redirect logic
│   └── theme/
│       └── app_theme.dart        ← Design system (colors, fonts, spacing)
│
├── features/                     ← One folder per product feature
│   └── auth/                     ← Everything related to login/register/profile
│       ├── data/
│       │   ├── models/
│       │   │   └── auth_models.dart         ← Data shapes (UserModel, AuthResponseModel)
│       │   └── repositories/
│       │       └── auth_repository.dart     ← HTTP calls for auth
│       └── presentation/
│           ├── bloc/
│           │   └── auth_bloc.dart           ← Auth state machine
│           └── pages/
│               ├── login_page.dart
│               ├── register_page.dart
│               ├── forgot_password_page.dart
│               └── other_pages.dart         ← CompleteProfilePage + HomePage
│
└── shared/
    └── widgets/
        └── shared_widgets.dart   ← Reusable UI components
```

---

## Every File Explained

---

### `lib/main.dart`

**What it is:** The front door of the app. Flutter calls `main()` first.

**What it does:**

- Loads `.env` file (so `API_BASE_URL` is available)
- Calls `initDi()` to wire up all dependencies
- Sets screen orientation (portrait only)
- Makes system bars transparent (edge-to-edge)
- Runs `NvrApp`

**What lives here:**

- `NvrApp` — creates `AuthBloc` and `AppRouter` once, wraps everything in `BlocProvider`, mounts `MaterialApp.router`
- `SplashScreen` — the loading screen shown while session is being restored
- Deep link listener (`_initDeepLinks`) — catches `nvr://auth/callback?token=...` from Google OAuth

**When to edit this file:**

- Changing app-wide theme mode (light/dark/system)
- Adding a new top-level provider
- Changing orientation lock
- Modifying how deep links are parsed

---

### `lib/injection_container.dart`

**What it is:** A registry of all objects in the app. GetIt is a "service locator" — like a global map of `Type → Instance`.

**What it does:**
Registers everything in dependency order:

```
Dio (HTTP engine)
  ↓
FlutterSecureStorage (encrypted storage)
  ↓
ApiClient (wraps Dio, adds auth headers)
  ↓
AuthRepository (uses ApiClient + Storage)
  ↓
AuthBloc (uses AuthRepository)
```

`registerLazySingleton` means: create it the first time it's asked for, then reuse the same instance forever.

**When to edit this file:**

- Adding a new Repository (e.g. `DeviceRepository` in Phase 2)
- Adding a new BLoC (e.g. `DeviceBloc`)
- Adding a new service (e.g. `NotificationService`)

---

### `lib/core/constants/app_constants.dart`

**What it is:** A single file with every magic string in the app.

**Why it exists:** Without this, you'd have `'/api/auth/login'` typed literally in 5 different files. If the backend changes the URL, you'd have to find all 5 places. With this file, you change it once.

**What lives here:**

- `baseUrl` — reads from `.env` (e.g. `http://192.168.1.5:8080`)
- All API endpoint paths (`/api/auth/login`, `/api/auth/me`, etc.)
- Secure storage keys (`access_token`, `user_profile`)
- Route paths (`/login`, `/home`, `/register`, etc.)
- Deep link scheme (`nvr`)
- App name, timeouts

**When to edit this file:**

- Backend changes an endpoint URL
- Adding a new route/page
- Adding a new storage key
- Adding a new API endpoint

---

### `lib/core/network/api_client.dart`

**What it is:** The app's single HTTP client. All network calls go through here.

**What it does:**

- Configures `Dio` with `baseUrl` and timeouts
- Adds `_AuthInterceptor` which:
  - **Before every request:** reads the JWT from secure storage and adds `Authorization: Bearer <token>` header automatically — so repositories don't have to do this manually
  - **After every error:** if status is `401`, triggers `AuthBloc.add(LogoutRequested())` globally — the user gets kicked to login from anywhere in the app without any page knowing about it
  - Standardizes error messages from Spring Boot's `ApiResponse` format into clean strings

**When to edit this file:**

- Adding a new header to all requests (e.g. `X-Tenant-ID` for multi-tenancy in Phase 2)
- Changing timeout durations
- Adding logging (e.g. print every request/response)
- Handling a new global error code (e.g. `403 Forbidden`)

---

### `lib/core/router/app_router.dart`

**What it is:** The navigation brain of the app. Controls which page is shown at all times.

**How it works:**
GoRouter has a `redirect` function that runs every time `AuthBloc` emits a new state (because `_GoRouterRefreshStream` converts the BLoC stream into a `ChangeNotifier` that GoRouter listens to).

**Redirect logic:**

```
AuthInitial         → /  (splash)
AuthUnauthenticated → /login
AuthProfileIncomplete → /complete-profile
AuthAuthenticated   → /home
  (and block going back to /login while authenticated)
```

**`_buildPage()` helper:** Defines the page transition once (fade + slide up). All 6 routes call this instead of repeating the animation code.

**When to edit this file:**

- Adding a new route/page (add a `GoRoute` entry)
- Changing redirect logic (e.g. adding an `INSTALLER` role check)
- Changing page transition animation
- Adding a nested route (e.g. `/home/camera/:id`)

---

### `lib/core/theme/app_theme.dart`

**What it is:** The entire design system in one file.

**What lives here:**

- **Static constants:** `amber`, spacing (`s8`, `s16`...), radii (`rMd`, `rLg`...), animation durations (`tSlow`, `tFast`...), curves (`curveEntrance`)
- **`AppColorsExtension`:** A `ThemeExtension` — custom colors/gradients that automatically switch between light and dark mode. Accessed anywhere via `Theme.of(context).extension<AppColorsExtension>()!`
- **`darkTheme` / `lightTheme`:** Full Material 3 `ThemeData` objects — colors, typography, input decoration, snackbars, etc.
- **`glassCard(context)`:** Returns a `BoxDecoration` for frosted glass cards — light/dark aware
- **`amberIconBox(context)`:** Returns a `BoxDecoration` for amber badge containers — light/dark aware

**When to edit this file:**

- Changing brand colors
- Adjusting spacing/radius values
- Modifying typography (font sizes, weights)
- Changing animation speed/curves
- Adding a new theme color or gradient
- Tweaking the glass card or button styles

---

### `lib/features/auth/data/models/auth_models.dart`

**What it is:** The data shapes (blueprints) that mirror what the Spring Boot backend sends.

**What lives here:**

- `UserModel` — mirrors `UserProfile` DTO from backend. Has `fromJson()` (parse API response) and `toJsonString()` (save to secure storage). Also has `isInstaller` getter and `copyWith()` for updating fields.
- `AuthResponseModel` — the shape of `/login` and `/register` responses: `{ accessToken, user }`

**When to edit this file:**

- Backend adds a new field to `UserProfile` (add it here too)
- Backend changes a field name (update `fromJson` key)
- Adding a new response model for a new endpoint

---

### `lib/features/auth/data/repositories/auth_repository.dart`

**What it is:** The only place that makes auth-related HTTP calls. Pages and BLoC never call `Dio` directly.

**What it does:**

- `register()`, `login()`, `logout()`, `completeProfile()`, `updateProfile()`, `forgotPassword()`, `handleGoogleSignIn()`
- Manages in-memory session (`_accessToken`, `_currentUser`)
- `_saveSession()` — writes JWT + user to encrypted storage
- `_clearSession()` — deletes both on logout
- `tryRestoreSession()` — reads from storage on app start; returns `true` if session exists

**Why separate from BLoC?** The repository only knows about HTTP and storage. It doesn't know about UI or state. This means you could swap it for a mock in tests, or swap the HTTP library, without touching any UI code.

**When to edit this file:**

- Adding a new auth endpoint
- Changing how the token is stored
- Adding token refresh logic later

---

### `lib/features/auth/presentation/bloc/auth_bloc.dart`

**What it is:** The state machine for authentication. This is the logic layer.

**Three parts:**

**Events** (things that happen):

```
AppStarted              — app opened, restore session
LoginRequested          — user submitted login form
RegisterRequested       — user submitted register form
GoogleAuthTokenReceived — deep link returned a token
ForgotPasswordRequested — user submitted forgot password
LogoutRequested         — user tapped logout (or 401 hit)
CompleteProfileRequested — user submitted phone number
UpdateProfileRequested  — user edited profile
```

**States** (what the app currently is):

```
AuthInitial           — just started, don't know yet
AuthLoading           — waiting for network
AuthAuthenticated     — logged in, profile complete → go to /home
AuthUnauthenticated   — not logged in → go to /login
AuthProfileIncomplete — logged in but no phone → go to /complete-profile
AuthError             — something went wrong (shown in ErrorBanner)
AuthActionSuccess     — one-off success (e.g. "reset email sent")
```

**Handlers** (`_onLogin`, `_onRegister`, etc.) — each calls a repository method and emits a new state based on the result.

**When to edit this file:**

- Adding a new auth action (new event + handler)
- Changing what state is emitted after login (e.g. adding email verification step)
- Adding loading states per-action

---

### `lib/features/auth/presentation/pages/login_page.dart`

**What it is:** The login screen UI only. No logic.

**What it does:**

- Shows email + password fields
- On submit: dispatches `LoginRequested` to BLoC
- Reads `AuthState` via `BlocBuilder` to show loading spinner or `ErrorBanner`
- "Forgot Password?" → `context.push('/forgot-password')`
- "Create account" → `context.push('/register')`
- Google button → launches browser via `url_launcher`

**When to edit this file:**

- Changing the login form layout
- Adding a "Remember me" checkbox
- Changing validation rules

---

### `lib/features/auth/presentation/pages/register_page.dart`

**What it is:** Registration screen. Same pattern as login page.

---

### `lib/features/auth/presentation/pages/forgot_password_page.dart`

**What it is:** Forgot password screen. Dispatches `ForgotPasswordRequested`, listens for `AuthActionSuccess` to show a snackbar and pop back.

---

### `lib/features/auth/presentation/pages/other_pages.dart`

**What it is:** Temporary home for `CompleteProfilePage` and `HomePage` (and their sub-widgets). Will be split into separate files in Phase 2 as `HomePage` grows.

**`CompleteProfilePage`:** Shown when user is authenticated but `profileComplete = false`. Collects phone number.

**`HomePage`:** The dashboard. Currently shows empty state. Phase 2 will add camera grid here.

---

### `lib/shared/widgets/shared_widgets.dart`

**What it is:** A library of reusable UI components used across multiple pages.

**What lives here:**

| Widget               | What it is                                                                  |
| -------------------- | --------------------------------------------------------------------------- |
| `AnimatedEntrance`   | Staggered fade + slide-up on mount. Use `delay:` to create cascade effect   |
| `PageBackground`     | Wraps page content with the mesh gradient background (amber + indigo blobs) |
| `AppWordmark`        | The "Sentinel" logo with icon — used on login + register                    |
| `GlassCard`          | Frosted glass container with light/dark-aware shadows                       |
| `PrimaryButton`      | Amber gradient button with press animation and loading spinner              |
| `SecondaryButton`    | Outlined ghost button                                                       |
| `GoogleSignInButton` | Google branded outlined button                                              |
| `AppTextField`       | Input field with animated focus glow, password visibility toggle            |
| `LabeledDivider`     | The "— or —" separator between email and Google sign-in                     |
| `ErrorBanner`        | Red inline error display                                                    |
| `SuccessBanner`      | Green inline success display                                                |
| `PulsingDot`         | Animated status indicator dot (used for "System online")                    |

**When to edit this file:**

- Changing button style app-wide
- Fixing input field behavior
- Adding a new shared component (e.g. `LoadingOverlay`, `ConfirmDialog`)

---

### `android/app/src/main/AndroidManifest.xml`

**What it is:** Android's app configuration file. Tells Android what your app can do.

**What's notable:**

- `android.permission.INTERNET` — allows network calls
- `android.permission.WAKE_LOCK` — allows `WakelockPlus` to keep screen on
- `android:launchMode="singleTop"` — prevents duplicate app instances when deep link opens the app
- The `intent-filter` with `nvr://auth` — registers your app to receive `nvr://` deep links (Google OAuth callback)

**When to edit this file:**

- Adding a new permission (e.g. camera access for Phase 2)
- Changing the deep link scheme
- Adding push notification config

---

## "Where Do I Go To Change X?" Quick Reference

| I want to change...              | Go to...                                                                                                 |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| The server URL                   | `app_constants.dart` → `baseUrl`                                                                         |
| An API endpoint path             | `app_constants.dart`                                                                                     |
| Colors / fonts / spacing         | `app_theme.dart`                                                                                         |
| Button style                     | `shared_widgets.dart` → `PrimaryButton`                                                                  |
| Input field style                | `shared_widgets.dart` → `AppTextField`                                                                   |
| Page transition animation        | `app_router.dart` → `_buildPage()`                                                                       |
| Which page shows after login     | `auth_bloc.dart` → `_onLogin()`                                                                          |
| Navigation / redirect rules      | `app_router.dart` → `redirect:`                                                                          |
| Login form layout                | `login_page.dart`                                                                                        |
| What happens on register success | `auth_bloc.dart` → `_onRegister()`                                                                       |
| Token storage key name           | `app_constants.dart` → `accessTokenKey`                                                                  |
| Add a new page                   | 1. Create file in `pages/`, 2. Add route in `app_router.dart`, 3. Add constant in `app_constants.dart`   |
| Add a new API call               | 1. Add endpoint in `app_constants.dart`, 2. Add method in repository, 3. Add event+state+handler in BLoC |
| Android permissions              | `AndroidManifest.xml`                                                                                    |
| App name                         | `app_constants.dart` → `appName` AND `android/app/build.gradle.kts` → `applicationId`                    |

---

## How the Auth Flow Works End-to-End

```
App opens
  │
  ├─ main.dart: dotenv.load() → initDi() → NvrApp()
  │
  ├─ NvrApp.initState(): getIt<AuthBloc>()..add(AppStarted())
  │
  ├─ AuthBloc._onAppStarted():
  │    AuthRepository.tryRestoreSession()
  │      ├─ Token found → emit AuthAuthenticated → GoRouter → /home
  │      └─ No token   → emit AuthUnauthenticated → GoRouter → /login
  │
  └─ User on /login, fills form, taps "Sign In"
       │
       ├─ LoginPage dispatches LoginRequested(email, password)
       │
       ├─ AuthBloc._onLogin():
       │    emit AuthLoading → page shows spinner
       │    AuthRepository.login() → Dio POST /api/auth/login
       │      ├─ Success → _saveSession(token, user) → emit AuthAuthenticated
       │      └─ Error   → emit AuthError("Wrong password")
       │
       ├─ GoRouter sees AuthAuthenticated → redirect to /home
       │
       └─ HomePage shows
```

---

## Phase 2 — Where New Code Will Go

When you build NVR device registration and camera live view:

```
lib/features/
├── auth/          ← already built ✅
├── devices/       ← NEW in Phase 2
│   ├── data/
│   │   ├── models/device_models.dart        ← NvrDevice, CameraChannel models
│   │   └── repositories/device_repository.dart ← register NVR, list cameras
│   └── presentation/
│       ├── bloc/device_bloc.dart
│       └── pages/
│           ├── add_device_page.dart
│           └── device_detail_page.dart
└── camera/        ← NEW in Phase 2
    └── presentation/
        └── pages/live_view_page.dart        ← WebRTC viewer
```

`injection_container.dart` gets `DeviceRepository` and `DeviceBloc` added.
`app_router.dart` gets `/devices`, `/devices/:id`, `/camera/:channelId` routes added.
`app_constants.dart` gets new endpoint constants added.
`HomePage` gets a camera grid instead of the empty state card.
