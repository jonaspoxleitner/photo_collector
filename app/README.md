# app — photo_collector guest app

Static Flutter Web app that lets event guests upload photos and videos
directly to S3-compatible object storage — no backend, no login. Event
configuration arrives via the `?d=` token in the QR code URL.

## Commands

All commands run through the repository FVM installation from this
directory:

```sh
fvm flutter pub get                                        # install dependencies
fvm flutter pub run build_runner build --delete-conflicting-outputs  # codegen
fvm flutter analyze                                        # static analysis
fvm flutter test                                           # unit and widget tests
fvm flutter run -d chrome --web-port 53618                  # local dev server
fvm flutter build web --release                            # production build
```

Or via the root Makefile: `make app-start`, `make app-deploy`.

## Local development with an event token

Run the dev server on **port 53618** (as `make app-start` does): the bucket
CORS configuration allows the dev origin `http://localhost:53618`, so uploads
against a real event bucket only work from that origin. Other ports are
fine for pure UI work with a fake configuration.

The app expects a full QR URL of the form `{base-url}/?d={base64url-json}`.
Example tokens live in `../test_fixtures/event_token_v1.json` (placeholder
credentials only). Launch Chrome with a fixture token by opening
`http://localhost:53618/?d=<token>` after `make app-start`.
A missing or malformed token renders the controlled invalid-config screen.

## Release build and deployment

`fvm flutter build web --release` writes deployable static artifacts to
`build/web/`. From the repo root, `make app-deploy` builds and deploys via
Firebase Hosting (overridable through `APP_DEPLOY_CMD`) — see
`../docs/deployment.md`.

## Localization

The app supports exactly English (`en`) and German (`de`). Strings live in
`lib/l10n/app_en.arb` / `lib/l10n/app_de.arb`; generated code lands in
`lib/l10n/generated/`. The initial locale follows the device/browser
language, falling back to English for unsupported locales.
