# cli — photo_collector host CLI

Host-side CLI for photo_collector; it currently provides QR card generation,
with more subcommands to come. The `qr-generate` subcommand mints the `?d=`
event token (the guest app decodes the same format), generates a compact QR
code with error-correction level H, clips a heart-shaped silhouette out of
the module grid (finder patterns and separators always stay intact), and
writes a print-ready, pure-vector SVG card.

This CLI is one step of the host workflow: bucket and IAM user creation,
deployment, scan testing, and teardown live in
[`../docs/host-runbook.md`](../docs/host-runbook.md),
[`../docs/bucket-setup.md`](../docs/bucket-setup.md), and
[`../docs/security-model.md`](../docs/security-model.md).

## Usage

Usually run from the repository root through the Makefile:

```sh
# Configuration from the root .env (copy .env.example first):
make cli-qr-generate

# Or override individual values with flags:
make cli-qr-generate QR_ARGS='--bucket wedding-20261025 --output card.svg'
```

Or directly:

```sh
fvm dart run bin/cli.dart qr-generate \
  --access-key ... --secret-key ... \
  --bucket wedding-20261025 --region eu-central-1 \
  --base-url https://photos.example.com --output card.svg
```

Or build a standalone binary from the same entrypoint:

```sh
fvm dart compile exe bin/cli.dart -o cli
```

## Configuration

Values are read from the process environment (the root `Makefile` exports the
git-ignored `.env`; see `.env.example` for all variables). Command-line flags
always take precedence over environment values.

| Flag             | Environment          | Required | Default     |
|------------------|----------------------|----------|-------------|
| `--access-key`   | `ACCESS_KEY_ID`      | yes      | —           |
| `--secret-key`   | `SECRET_ACCESS_KEY`  | yes      | —           |
| `--bucket`       | `BUCKET`             | yes      | —           |
| `--region`       | `REGION`             | yes      | —           |
| `--endpoint`     | `ENDPOINT`           | no       | AWS S3      |
| `--base-url`     | `BASE_URL`           | yes      | —           |
| `--output`       | `OUTPUT`             | no       | `card.svg`  |
| `--title`        | `TITLE`              | no       | none        |
| `--foreground`   | `FOREGROUND`         | no       | `#000000`   |
| `--background`   | `BACKGROUND`         | no       | `#ffffff`   |
| `--heart-mode`   | —                    | no       | `frame`     |
| `--heart-scale`  | —                    | no       | `0.15` (frame) / `0.3` (cut) |
| `--heart-padding`| —                    | no       | `2` (frame) / `0.8` (cut)  |
| `--heart-vshift` | —                    | no       | `0.1` (frame) |
| `--preview` / `--no-preview` | —        | no       | on          |
| `--help`, `-h`   | —                    | —        | —           |

- `--heart-mode frame` (default) draws decorative fake modules in a heart
  silhouette *around* the QR code. The code — including its quiet zone — is
  never touched, so the card stays scannable at any heart size.
  `--heart-scale` then dilates the heart beyond its minimal enclosing size;
  `--heart-padding` widens the white gap between quiet zone and frame;
  `--heart-vshift` moves the heart down relative to the code (in curve
  units) so the code sits higher inside the heart.
- `--heart-mode cut` clips a heart silhouette out of the center of the code,
  relying on error-correction level H (~30% recovery). `--heart-scale` is
  the fraction of the QR width covered; `--heart-padding` adds a clipped
  safety margin. **Cut mode demands careful scan testing**: scale 0.62
  failed real-device scanning; 0.3 was scan-tested and is the default there.
- The CLI validates the foreground/background contrast ratio and refuses
  unusable combinations (light-on-dark or < 2:1 contrast).
- Secret values are never printed.
- Exit codes: `0` success, `64` bad/missing arguments, `65` unusable input
  data (colors, overlong payload), `74` output write failure.

## Scan testing

After every generation the CLI prints the mandatory reminder: scan-test the
card from a **real phone**, at the **final print size** with the QR **at
least 4 cm wide**, and **in dim light** (candles, evening venue lighting).
The terminal preview (`--preview`, on by default) is for a quick check only —
always verify the exported SVG at print size.

## Security

The QR payload embeds the storage credentials (`{k,s,b,r,ep?}` as
base64url-encoded JSON). Every guest who scans the card can read them, so:

- use ONLY the per-event put-only IAM key — never an admin key,
- keep `.env` out of version control (it is git-ignored),
- revoke the credentials immediately after downloading the event archive.

## Development

```sh
fvm dart pub get
fvm dart analyze
fvm dart test
```

Tests share the token fixture at `../test_fixtures/event_token_v1.json` with
the guest app to prevent format drift.
