# AWS bucket setup

Per-event storage setup for photo_collector. Everything below runs in the
AWS Management Console; no CLI required. Paste-ready JSON files live in
`infra/`.

Architecture: **one project per event**. Each event gets its own S3 bucket,
its own Firebase Hosting project, and its own IAM user — all named after
the event ID. The IAM user's inline policy allows `s3:PutObject` in the
event bucket only. After the event, delete the IAM user, the bucket, and
the hosting project, and the event is fully gone.

This document is the detailed reference for bucket/IAM/CORS setup. The full
event lifecycle with the mandatory teardown sequence is in
`docs/host-runbook.md`; the rationale for every mandatory step is in
`docs/security-model.md`.

Naming convention: `project name = bucket name = event ID`. Both Firebase
project IDs and S3 bucket names are globally unique, lowercase, and use
letters/digits/hyphens, so one name works for both. Pick names that are
unlikely to collide globally, e.g. `wedding-anna-ben-2026` rather than
`wedding`.

Decide first:

| Decision | Notes |
|---|---|
| Event ID | Lowercase letters, digits, hyphens (e.g. `wedding-anna-ben-2026`). Used as project name and bucket name. |
| Region | Closest to most guests, e.g. `eu-central-1` for DACH. This **is** the SigV4 signing region (`r` in the QR token) — it must equal the bucket's region. |

## 1. Create the bucket

S3 → **Create bucket**:

- **Bucket name**: the event ID. **AWS Region**: as decided above. If the
  name is globally taken, pick a more specific event ID and use it
  everywhere.
- **Object Ownership**: ACLs disabled (default). Keep it — access control
  happens entirely via IAM policies.
- **Block all public access**: **On** (default). Mandatory.
- Default encryption: **SSE-S3** (default; ignore the "Bucket Key" option —
  it only applies to SSE-KMS).
- No lifecycle rules. Deletion is a deliberate manual step after each event
  (see "After the event").

## 2. Firebase project and CORS

Create the hosting project at console.firebase.google.com with the same
event-derived name (project ID = event ID). The app origin becomes
`https://<event-id>.web.app`; `firebase use --add` wires the repo to it
(see `docs/deployment.md`).

Then S3 → bucket → **Permissions** → **Cross-origin resource sharing
(CORS)** → **Edit** → paste `infra/bucket-cors.json`, replacing the
production placeholder origin with the project's origin:

- Origins must match exactly: scheme included, no trailing slash.
- Keep `http://localhost:5000` for local development (run Flutter with
  `--web-port 5000` so the origin stays stable).
- `AllowedMethods` stays `PUT` only; `ExposeHeaders` stays `ETag`.

## 3. Per-event IAM user and inline policy

IAM → **Users** → **Create user**:

- **User name**: `photo-collector-<event-id>`.
- Do **not** enable console access — this user never logs in.
- On the permissions step, select **nothing** and finish. The wizard cannot
  create inline policies; they are added afterwards.

Then, on the user's page: **Permissions** → **Add permissions** →
**Create inline policy** → **JSON** tab → paste
`infra/s3-put-only-policy.template.json` **with the `${BUCKET}` placeholder
substituted**, e.g.:

```json
"Resource": "arn:aws:s3:::wedding-anna-ben-2026/*"
```

Name the policy `put-only` → **Create policy**.

Important:

- The policy must be **inline** (created on the user), not a
  customer-managed policy. An inline policy dies with the user, so per-event
  revocation is one deletion and policies are never reused across events.
- AWS accepts the literal `${BUCKET}` placeholder silently. If it is not
  substituted, the policy matches nothing and every upload fails with
  AccessDenied — double-check the final `Resource` string before saving.
- Do not add a bucket policy in S3. Guest authorization lives entirely on
  the IAM user.

## 4. Access key (the QR credential)

User → **Security credentials** → **Create access key** → use case
**Other** → **Create access key**.

The secret is shown **once**. Store both values immediately. This pair is
what goes into the QR code — it is the per-event put-only key, never an
admin key.

## 5. Verify write-only behavior

The CLI proves the put-only credential behaviorally against the real bucket:
a signed `PutObject` must succeed, and a signed `GetObject` and a signed
`DeleteObject` of the same probe object must both be denied. Only the guest
credential is used — no admin key is involved.

Copy `.env.example` to `.env` and fill in the step-4 values (and `REGION`) as
in §7, then run from the repo root:

```sh
make cli-bucket-verify
```

The command exits `0` only when all three probes pass:

| Output line | Meaning |
|---|---|
| `Write probe (PUT):  PASS (HTTP 200, ETag …)` | the key can upload |
| `Read probe (GET):  PASS (HTTP 403 AccessDenied).` | the key cannot download |
| `Delete probe (DELETE):  PASS (HTTP 403 AccessDenied).` | the key cannot delete |
| `Put-only policy verified: …` | all probes passed |

Any other outcome is a failure with an actionable hint:

| Failure | Likely cause |
|---|---|
| `AccessDenied` on PUT | the inline policy still contains the literal `${BUCKET}` placeholder — re-apply `infra/s3-put-only-policy.template.json` with it substituted |
| `301` / `PermanentRedirect` | `REGION` or `ENDPOINT` does not match the bucket |
| `SignatureDoesNotMatch` | `SECRET_ACCESS_KEY` is wrong or does not belong to `ACCESS_KEY_ID` |
| read probe succeeds (exit `65`) | the policy is wider than put-only — restrict it to `s3:PutObject` only |
| delete probe succeeds (exit `65`) | the policy grants `DeleteObject` — restrict it to `s3:PutObject` only (the `infra/s3-put-only-policy.template.json` template grants `PutObject` only) |

Exit codes: `0` all probes as expected, `64` bad/missing arguments, `65` the
read or delete probe unexpectedly succeeded, `70` the write probe or the
network failed. Flags (`--access-key`, `--secret-key`, `--bucket`, `--region`,
`--endpoint`) override `.env` values; see `cli/README.md`.

Notes:

- The probe object (`.photo-collector-verify/<timestamp>.png`) **stays in the
  bucket until teardown**. The put-only credential cannot delete it; emptying
  the bucket in "After the event" removes it. If the delete probe unexpectedly
  succeeds, the command notes that the permitted delete already removed the
  probe object.
- This verifies the IAM policy, not CORS. Presigned-URL requests are not
  browser requests, so the cross-origin path is exercised only by the browser
  smoke test in `docs/host-runbook.md` §1.11 — that test remains mandatory.
- The console **Simulate** check is now optional. If you still want it, on the
  user's Permissions tab tick the policy's checkbox and run:

  | Action | Resource | Expected |
  |---|---|---|
  | `s3:PutObject` | `arn:aws:s3:::<bucket>/photo.jpg` | allowed |
  | `s3:GetObject` / `s3:ListBucket` | bucket | denied |

## 6. Billing alert (mandatory, one-time)

Billing → **Budgets** → **Create budget** → cost budget, monthly, small
amount (e.g. USD 5) with an email alert. This is the leak alarm: escaped QR
credentials cause runaway uploads that show up here first. Account-level —
create once, it covers all events. (No automatic deletion is configured;
cost control relies on the alert plus revocation.)

## 7. Wire the values into the QR tooling

Copy `.env.example` to `.env` (git-ignored, never commit) and fill it:

| `.env` variable | Value |
|---|---|
| `ACCESS_KEY_ID` / `SECRET_ACCESS_KEY` | from step 4 |
| `BUCKET` | the event ID (bucket name = event ID) |
| `REGION` | bucket region (e.g. `eu-central-1`) |
| `BASE_URL` | `https://<event-id>.web.app` |
| `ENDPOINT` | omit for AWS default endpoints |

Then `make cli-qr-generate` (CLI flags override `.env` values if supplied).
The event name is not part of the token — the bucket carries it.

## After the event

AWS IAM access keys **do not expire natively** — deletion is the only
kill-switch and is mandatory, not optional:

1. Download the full archive of the event bucket.
2. IAM → Users → `photo-collector-<event-id>` → **Delete** (this removes
   the access key and the inline policy with it).
3. Delete the bucket (empty it first: bucket → **Empty**).
4. Delete the Firebase project (project settings → **Delete project**).

The only piece that survives across events is the account-level billing
budget. Repeat steps 1–5 and 7 for each new event.
