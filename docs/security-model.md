# Security model

photo_collector has no backend and no database. Guests upload directly from
their browser to a per-event S3 bucket using credentials embedded in the QR
code. This document states exactly what that protects, what it does not, and
which host controls are mandatory. It matches the actual implementation —
read it together with `docs/bucket-setup.md` (the concrete AWS setup).

## Design invariants

These are properties of the implemented system, not aspirations:

- **Fully static client.** The app is HTML/JS/Wasm artifacts served by
  static hosting. There is no server-side component that could leak or
  amplify credentials.
- **Write-only, bucket-scoped guest credentials.** The QR code embeds an IAM
  access key whose inline policy allows exactly one action —
  `s3:PutObject` — and exactly one resource —
  `arn:aws:s3:::<event-bucket>/*` (see
  `infra/s3-put-only-policy.template.json`). Guests cannot read, list,
  update, or delete anything with these credentials. Object creation outside
  the event bucket is denied.
- **Private bucket.** The event bucket keeps AWS's default "Block all public
  access" setting. Nobody can read objects without the host's own account
  credentials. Do not add bucket policies, ACLs, or public web hosting.
- **CORS restricts origins.** `infra/bucket-cors.json` permits `PUT` only,
  from exactly two origins: the production app origin (placeholder —
  must be replaced with the real deployed domain) and
  `http://localhost:53618` for local development. `ETag` is exposed so the
  app can confirm uploads. No other methods are allowed cross-origin.
- **Per-event infrastructure.** Bucket, hosting project, and IAM user are
  named after the event ID, created for one event, and deleted after it.
  Credentials are never reused across events — every event starts with a
  fresh IAM user.
- **Unique, sanitized object keys.** The client builds keys as
  `{sanitized-name}-{batch-uuid4}/{safe-original-filename}`. The guest name
  is lowercased, trimmed, stripped of unsupported characters, length-limited,
  and falls back to `anonymous`; a fresh UUID per upload batch makes
  overwrites and collisions impossible regardless of what a guest tries.
  A guest cannot make one upload overwrite another.
- **No credential persistence.** Credentials arrive via the `?d=` URL
  parameter, are held in memory only, and are never written to local
  storage, cookies, analytics, or logs. The app contains no telemetry.

## Accepted risks (explicitly accepted for v1)

- **Any QR holder can upload until credentials are revoked.** The QR code
  *is* the capability. Anyone who scans or photographs it — including people
  the card is photographed in front of — can upload arbitrary content to the
  event bucket until the host deletes the access key. This is the accepted
  v1 risk; the mitigation is the mandatory revocation step after the event
  plus the billing alert as the leak alarm.
- **Credentials are visible to every guest.** The access key ID and secret
  appear in the QR payload and in every guest's browser URL bar and
  **browser history**. A curious guest can extract and reuse them on another
  device. There is no mitigation that keeps using static QR cards — this is
  why the key must be write-only and why revocation is non-negotiable.
- **Guests can upload anything.** There is no server-side moderation,
  scanning, or content-type enforcement in v1. The browser file picker
  requests `image/*,video/*`, but a determined attacker with the token can
  PUT any bytes. The host must review the archive and clean it up manually
  before sharing photos from it.
- **Single-PUT size limit.** Uploads are single signed PUTs with a
  documented 2 GB maximum; on phones the practical limit is lower because
  picked files are buffered in browser memory.
- **Denial-of-wallet.** Escaped credentials could be used to flood the
  bucket with uploads, generating storage and request costs. Mitigations:
  per-event bucket (blast radius limited to one event), mandatory billing
  budget alert, and immediate key deletion.

## Mandatory safety controls

These steps are **not optional**. The host runbook
(`docs/host-runbook.md`) sequences them; skipping any of them turns an
accepted risk into an unmitigated one.

1. **Never put admin credentials in the QR code or the app.** The only key
   that may ever be minted into a QR token is the per-event, put-only,
   bucket-scoped IAM key. The `.env.example` template and both READMEs
   repeat this because it is the single most damaging mistake available.
2. **Immediate credential deletion after archive retrieval.** AWS IAM
   access keys **do not expire natively** — there is no automatic timeout.
   Deleting the per-event IAM user (which deletes its access key and inline
   policy) after downloading the archive is the **only kill-switch** and is
   a mandatory, non-skippable runbook step. "I'll do it later" is the
   classic way leaked QR cards keep accepting uploads for months.
3. **Billing/storage alerts before the event.** The account-level AWS
   Budget with an email alert is a mandatory setup step. Runaway uploads
   from leaked credentials show up there first.
4. **New credentials per event.** Never reuse a previous event's IAM user
   or rotate-in-place. Fresh user, fresh key, fresh bucket per event.
5. **HTTPS hosting.** The app must be served over HTTPS (Firebase Hosting's
   default) so the token is not exposed in transit.
6. **Keep `.env` out of version control.** It is git-ignored; only
   `.env.example` with placeholder values may be committed.

## Guest data and privacy

- The guest name a person enters is sanitized and embedded in the object key
  as the folder name (`anna-smith-a1b2…/IMG_1234.jpg`). It is visible to the
  host when reviewing the archive, but to no one else: the bucket is
  private and guest credentials cannot list it. Guests may leave the name
  empty, in which case files land in an `anonymous-…` folder.
- Uploaded files are accessible **only through the host's AWS account**.
  The thank-you screen (en/de) tells guests this, that their name is visible
  to the host, and that event storage is deleted after the event.
- **Cleanup is manual.** After the event the host downloads the archive
  locally, reviews and curates it (removing anything that should not be
  kept or shared), and then deletes the IAM user, the bucket, and the
  hosting project. Nothing is retained by the system itself.
- Guest browser history retains the token URL; advise guests who ask that
  clearing history removes it — harmless after revocation regardless.

## Revocation as rollback

The instant response to any suspected credential leak during an event is:

```text
AWS Console → IAM → Users → photo-collector-<event-id> → Delete
```

or deactivate the access key first if uploads should stop but the user
should be kept for the moment. Deleting the IAM user removes the key **and**
the inline policy in one action. To remove guest access to the app itself,
remove or replace the deployed static hosting build.
