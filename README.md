# photo_collector

Fully static, self-hosted photo and video collection app for private events
(weddings, parties). Guests scan a QR code, open a Flutter Web page — no log
in, no app install — optionally enter their name, and upload photos/videos
directly to S3-compatible object storage. **There is no backend and no
database.**

The QR code embeds a token with **write-only** storage credentials
(`{base-url}/?d={base64url-json}` containing `{k,s,b,r,ep?}`). The app signs
S3 requests client-side with SigV4 and PUTs files straight to the per-event
bucket; the host revokes the credentials after the event. A separate Dart CLI
generates print-ready SVG QR cards (error-correction level H, heart-shaped
silhouette mask, intact finder patterns).

## Repository layout

```
app/              Flutter Web guest app (landing with inline upload status → thank-you)
cli/              Dart CLI: mints the event token, renders the heart-masked SVG card
docs/             Host runbook, bucket setup, deployment, security model
infra/            Paste-ready IAM put-only policy template and bucket CORS rules
test_fixtures/    Shared token fixture used by app and CLI tests (placeholders only)
Makefile          Operational shortcuts: app-start, app-deploy, cli-qr-generate, cli-qr-generate-heart
.env.example      QR configuration template — copy to .env (git-ignored!)
```

## Quick start (host)

```sh
make app-start                 # run the guest app in Chrome (port 5000, matches CORS dev origin)
make app-deploy                # build web release + firebase deploy (APP_DEPLOY_CMD overridable)
make cli-qr-generate               # plain QR card (no heart) from .env values
make cli-qr-generate QR_ARGS='--title "Anna & Ben" --output card.svg'   # flags override .env
make cli-qr-generate-heart HEART_SCALE=0.8 HEART_PADDING=1.2   # tune the heart mask
```

`make cli-qr-generate` exits with a helpful message if neither `.env` nor
`QR_ARGS` provides configuration. Deployment defaults to Firebase Hosting
(`firebase deploy --only hosting`); override with
`make app-deploy APP_DEPLOY_CMD='./scripts/deploy.sh'` for any other static
HTTPS host.

All builds use the repo-pinned FVM SDK (`fvm flutter` / `fvm dart`).

## Security in one paragraph

The QR code embeds per-event IAM credentials that can only `s3:PutObject`
into the private event bucket — never read, list, or delete. Anyone holding
a QR card can therefore upload until the host deletes the key (the accepted
v1 risk). Read [`docs/security-model.md`](docs/security-model.md) before
running a real event; **never** put admin credentials in a QR code or the
app, and revoke credentials immediately after retrieving the archive — AWS
IAM keys do not expire on their own.

## Documentation

- [docs/host-runbook.md](docs/host-runbook.md) — create → operate → tear
  down an event, with the final operational checklist
- [docs/bucket-setup.md](docs/bucket-setup.md) — S3 bucket, CORS, per-event
  IAM user, billing alert
- [docs/deployment.md](docs/deployment.md) — static web deployment (Firebase
  Hosting default)
- [docs/security-model.md](docs/security-model.md) — threat model, accepted
  risks, mandatory controls, guest privacy
- [app/README.md](app/README.md) — guest-app development and release builds
- [cli/README.md](cli/README.md) — host CLI: `qr-generate` flags, exit
  codes, scan testing

## License

MIT — see [LICENSE](LICENSE).
