# Host runbook

End-to-end operating guide for running one event with photo_collector, from
account preparation to teardown. Follow it top to bottom; every step that
says **mandatory** is non-skippable — see `docs/security-model.md` for why.

Prerequisites on the host machine:

- repo cloned, FVM installed (`fvm use` picks the pinned Flutter/Dart SDK)
- Firebase CLI installed and logged in (`firebase login`) for `app-deploy`
- an AWS account for S3
- **one-time:** account-level billing budget with email alert (mandatory —
  this is the leak alarm for escaped QR credentials). See
  `docs/bucket-setup.md` §6. Verify it still exists before each event.

Work through this file with the detailed references open:

| Topic | Document |
|---|---|
| S3 bucket, CORS, IAM user, access key, billing alert | `docs/bucket-setup.md` |
| Deploying the web app | `docs/deployment.md` |
| Threat model, mandatory controls, privacy | `docs/security-model.md` |
| CLI flags and card options | `cli/README.md` |

---

## 1. Create the event (days/weeks before)

1.1 **Pick the event ID.** Lowercase letters, digits, hyphens, globally
unlikely to collide: `wedding-anna-ben-2026`, not `wedding`. It becomes the
bucket name, the IAM user suffix, and the Firebase project ID.

1.2 **Create the S3 bucket.** Follow `docs/bucket-setup.md` §1: region
closest to most guests, "Block all public access" **on** (mandatory),
no public access anywhere. Note the region — it is the SigV4 signing
region in the QR token and must equal the bucket region.

1.3 **Create the Firebase project** with the same event ID as project ID.
The app origin will be `https://<event-id>.web.app`. Run
`firebase use --add` from the repo root and select it so `.firebaserc`
points at this event. Details: `docs/deployment.md`.

1.4 **Configure bucket CORS.** Paste `infra/bucket-cors.json` into the
bucket's CORS settings and **replace the production origin placeholder with
the real app origin** (`https://<event-id>.web.app`, no trailing slash).
Keep `http://localhost:53618` for local testing. Without this step every
browser upload fails.

1.5 **Create the per-event IAM user** `photo-collector-<event-id>` with an
**inline** policy pasted from `infra/s3-put-only-policy.template.json`,
`${BUCKET}` substituted. This user permits exactly `s3:PutObject` inside the
event bucket and nothing else. **Never use admin credentials — in the QR
code or the app.** (Mandatory; details in `docs/bucket-setup.md` §3.)

1.6 **Create the access key** on that user and store it somewhere safe.
This pair goes into the QR code — treat it accordingly.

1.7 **Verify write-only behavior** with the IAM policy simulator:
`PutObject` allowed, `GetObject`/`ListBucket` denied
(`docs/bucket-setup.md` §5).

1.8 **Deploy the app:**

```sh
make app-deploy        # builds app/ and runs firebase deploy --only hosting
```

Confirm the deployed URL loads and shows the app shell. A missing/invalid
link shows the controlled "invalid event link" screen — expected before the
token exists.

1.9 **Configure the QR tooling.** At the repo root:

```sh
cp .env.example .env   # .env is git-ignored; never commit it
```

Fill in `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY`, `BUCKET` (= event ID),
`REGION`, `BASE_URL` (= `https://<event-id>.web.app`). Then:

```sh
make cli-qr-generate                 # all values from .env
# or override any value with flags:
make cli-qr-generate QR_ARGS='--title "Anna & Ben" --output anna-ben.svg'
```

The CLI writes the SVG card and prints the mandatory scan-test reminder.
Secret values are never echoed; the card files themselves embed the
credentials, so treat the SVG like a key.

1.10 **Scan-test the printed card (mandatory final checklist).** Print at
final size and verify with **real phones** (several models, iOS and
Android): the QR must be **at least 4 cm wide** and must scan **in dim
light** — candles, evening venue lighting — not just at your desk. If any
phone fails, increase the print size or reduce `--heart-scale` and
regenerate.

1.11 **Live guest-upload smoke test (mandatory final checklist).** Before
the event, scan the card with a real phone, enter a test name, upload one
photo, and confirm the object lands in the event bucket under
`<test-name>-<uuid>/…`. Then try reading or listing the bucket with the QR
credentials (e.g. via an S3 client) and confirm both are **denied**. Delete
the test object afterwards.

## 2. Operate the event

- Place the printed cards at the venue. Guests scan, optionally enter a
  name, pick photos/videos, upload. There is nothing for you to run.
- Keep an eye on the billing alert email — unexpected charges mean escaped
  credentials (see incident response below).
- Single-file uploads are capped at 2 GB per file; phones often handle far
  less. Guests with a huge video can retry on a laptop or hand it to you
  directly.
- The app UI follows the guest's device language (English/German);
  unsupported locales fall back to English.

**Incident response (mandatory, immediate):** suspected credential leak →
AWS Console → IAM → Users → `photo-collector-<event-id>` → deactivate (or
delete) the access key. Uploads stop within seconds. To remove app access,
delete the deployed hosting site.

## 3. After the event (mandatory teardown)

**AWS IAM access keys do not expire natively.** Deleting the key is the only
kill-switch, and it must happen immediately after you have the archive —
not "sometime next week".

1. **Download the full archive** of the bucket to local storage (console:
   select all → download, or `aws s3 sync s3://<event-id> ./archive` with
   *your own* admin credentials — never the QR key).
2. **Review and clean up** the archive manually: guest names are folder
   prefixes; remove anything that should not be kept or shared before
   curating the final photo set.
3. **Delete the IAM user** `photo-collector-<event-id>` (mandatory — this
   deletes the access key and the inline policy in one action).
4. **Confirm revocation:** a PUT with the QR credentials now fails.
5. **Empty and delete the bucket.**
6. **Delete the Firebase project** (Project settings → Delete project).
7. The account-level billing budget stays for the next event; everything
   else from this event is gone.

For the next event, start again at §1: new event ID, new bucket, new IAM
user, **new credentials** (mandatory — never reuse).

---

## Final operational checklist

- [ ] Billing budget with email alert exists (one-time, account-level)
- [ ] Bucket created: public access blocked, no bucket policy/ACLs
- [ ] CORS pasted with **real** production origin replacing the placeholder
- [ ] IAM user `photo-collector-<event-id>` with inline put-only policy;
      `${BUCKET}` substituted; simulator shows PutObject allowed,
      Get/List denied
- [ ] Access key created; **no admin credentials anywhere near the QR/app**
- [ ] App deployed (`make app-deploy`) and loads over HTTPS
- [ ] `.env` filled; `make cli-qr-generate` produced the card; card kept secure
- [ ] **Real-device scan test:** ≥ 4 cm wide, several phones, dim light
- [ ] **Live guest upload test** against the real event bucket; read/list
      with QR credentials confirmed denied
- [ ] Cards placed at the venue
- [ ] After the event: archive downloaded → IAM user deleted immediately →
      bucket emptied/deleted → Firebase project deleted
