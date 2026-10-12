# Deployment — static web hosting

The guest app is a fully static Flutter Web build (no backend, no database).
Anything that can serve static files over **HTTPS** can host it. Firebase
Hosting is the demonstrated default path and is wired into the Makefile.

## Build

```sh
cd app
fvm flutter pub get
fvm flutter pub run build_runner build --delete-conflicting-outputs  # first run / after model changes
fvm flutter build web --release
```

The deployable artifacts land in `app/build/web/`. Serve that directory —
that is all deployment is.

## Default path: Firebase Hosting (per event)

Per-event infrastructure: **one Firebase project per event**, named after
the event ID, deleted after the event together with the bucket and the IAM
user (see `docs/host-runbook.md`).

1. Create a Firebase project at <https://console.firebase.google.com> with
   the **event ID as the project ID** (e.g. `wedding-anna-ben-2026`).
   Analytics are not needed.
2. From the repo root, wire the repo to it once per event:

   ```sh
   firebase use --add        # select the event project, alias "default"
   ```

   This rewrites `.firebaserc` (`projects.default`). Do this **per event** —
   the previous event's project must not receive a new event's app.
3. Deploy:

   ```sh
   make app-deploy
   ```

   which runs `fvm flutter build web --release` in `app/` and then
   `firebase deploy --only hosting`.

`firebase.json` already serves `app/build/web` and rewrites all paths to
`index.html` (required for the app's path-based URLs and the `?d=` token).
The app is then live at `https://<event-id>.web.app` (plus
`.firebaseapp.com`) — HTTPS is provided by Firebase; do not host the app
over plain HTTP, because the QR token carries credentials.

That origin is also what goes into:

- `BASE_URL` in `.env` (QR codes point here), and
- the **production origin** in `infra/bucket-cors.json` (replace the
  placeholder; bucket uploads fail with CORS errors otherwise).

## Rolling updates / rollback

- Update: run `make app-deploy` again; Firebase Hosting releases are
  atomic.
- Rollback: `firebase hosting:rollback`, or redeploy the previous commit.
  No database migrations or backend redeploys exist.
- To remove guest access entirely: delete the hosting site or the project.

## Other static hosting providers

Any HTTPS static host works. Override the deploy command:

```sh
make app-deploy APP_DEPLOY_CMD='./scripts/deploy.sh'
```

If the app lives at a different origin, update `BASE_URL` in `.env` **and**
the production origin in `infra/bucket-cors.json` accordingly — origins must
match exactly (scheme included, no trailing slash).

## Local development

```sh
make app-start
```

runs the app in Chrome on a **fixed port 5000**, which matches the
`http://localhost:5000` dev origin in the bucket CORS configuration — local
uploads against a real event bucket only work from that origin. Open the
app with a token URL (`http://localhost:5000/?d=<token>`); placeholder
tokens for UI development live in `test_fixtures/event_token_v1.json`.
