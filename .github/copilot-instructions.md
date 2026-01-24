# Copilot / AI Agent Instructions — The_Hackstreet_Boyz

Purpose
- Help an AI coding agent quickly understand and contribute to this repo.

Quick start (dev machine)
- Work primarily inside the `luscid/` folder — this is the Flutter app.
- Install & configure Flutter SDK, then run:

  - `cd luscid && flutter pub get`
  - `flutter run` (choose device) or `flutter run -d windows` on Windows
  - `flutter test` (runs unit & widget tests under `test/`)
  - `flutter build apk` / `flutter build ios` for platform builds

Notes: iOS builds require Xcode + CocoaPods; Android uses the bundled Gradle wrapper in `android/`.

Architecture (what matters)
- Frontend: Flutter app at `luscid/` (entry: `luscid/lib/main.dart`).
- State: `provider` + `ChangeNotifier` pattern. Providers live in `luscid/lib/providers/` and are named `*Provider`.
- UI: screens under `luscid/lib/screens/`, routes are declared in `main.dart` (named routes map).
- Services: reusable logic in `luscid/lib/services/` (example: `local_storage_service.dart` initialized in `main`).
- Models: domain models in `luscid/lib/models/`.
- Real-time/voice: `luscid/lib/ptt/` contains PTT integration (Zego/ZEGOCLOUD) and related channels.
- Backend: Firebase packages are present (`firebase_core`, `firebase_auth`, `firebase_database`) but server backend code is not part of this repo.

Key files to inspect first
- [.github/copilot-instructions.md](.github/copilot-instructions.md) — original file.
- [luscid/pubspec.yaml](luscid/pubspec.yaml) — dependency matrix.
- [luscid/lib/main.dart](luscid/lib/main.dart) — app bootstrap, providers, routes, and `LocalStorageService.init()`.
- [luscid/lib/providers/](luscid/lib/providers/) — state management pattern examples.
- [luscid/lib/services/local_storage_service.dart](luscid/lib/services/local_storage_service.dart) — local init pattern.
- [luscid/lib/ptt/](luscid/lib/ptt/) — real-time voice glue; check `ptt_channel.dart` and `ptt_module.dart`.
- [luscid/android/app/google-services.json](luscid/android/app/google-services.json) and FIREBASE_PHONE_AUTH_INSTRUCTIONS.md — Firebase setup & phone auth notes.

Conventions & patterns specific to this repo
- Provider pattern: Create a `ChangeNotifier` in `lib/providers/`, register in `main.dart`'s MultiProvider, and access via `Provider.of<T>(context)` or `context.watch<T>()`.
- Routes: Use named routes defined in `main.dart`'s `routes` map; prefer pushing named routes to maintain consistency.
- Initialization: App-level services are initialized in `main()` (Firebase + `LocalStorageService.init()`). Mirror this pattern for new global services.
- Files/dirs to touch for UI changes: `lib/screens/` + `lib/widgets/`; keep accessibility in mind (large targets, `Semantics` widgets, high-contrast fonts).
- Linting: `analysis_options.yaml` and `flutter_lints` are active — follow existing style.

Integration & secrets
- Firebase: Android `google-services.json` is already included for the Android app; iOS requires editing `ios/Runner/Info.plist` and adding GoogleService-Info.plist if used.
- Do NOT commit service account keys or secrets. If adding external credentials, add a README fragment explaining required env vars and a safe local fallback.
- Phone auth: see `FIREBASE_PHONE_AUTH_INSTRUCTIONS.md` for environment-specific steps.

Developer workflows
- Adding dependencies: edit `luscid/pubspec.yaml` and run `flutter pub get` from `luscid/`.
- Running app: prefer using `flutter run` on a test device/emulator; on Windows use `flutter run -d windows`.
- Running tests: `cd luscid && flutter test`.
- Building release: `cd luscid && flutter build apk` (Android) or `flutter build ios` (iOS, on macOS).

Testing structure
- Tests live under `test/` and mirror app structure (`unit/`, `integration/`, `models/`, `services/`).
- Add widget tests for screens under `lib/screens/` and unit tests for providers and services.

PR & commit guidance
- Small, focused commits. Use prefixes: `feat:`, `fix:`, `docs:`.
- PR description: problem statement, changes made, testing steps, and migration notes (if any).

When to ask maintainers (quick checklist)
- Which backend to integrate with (Firebase vs Supabase vs custom)?
- Are we allowed to add runtime credentials to CI or should we provide local-only fallbacks?
- Any design/asset constraints for UI (fonts, icon sets, accessibility requirements)?

If you update/integrate external systems
- Add a short README fragment under `luscid/` describing required env vars, how to obtain keys, and a safe local dev fallback.

Feedback
- After making non-trivial changes (new deps, platform setup, or integration code) open a PR and ping the repo owner for review.
