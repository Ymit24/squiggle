# squiggle-feedback-api

A small Rust (axum) service behind the app's **Report a bug / idea** button.
It accepts a title, description and kind, then opens a GitHub issue labelled
`app-submission` plus `bug` or `enhancement`. To see every submitted report:

```
is:issue label:app-submission
```

## Security model

The service only lets a caller do one thing: open a rate-limited issue whose
contents it has sanitized.

- **GitHub token:** use a fine-grained PAT scoped to the one repository, with
  only **Issues: Read and write**. If the service were fully compromised, the
  token still could not touch code, settings or other repositories. The
  service never shells out; it sends JSON straight to the REST API.
- **Client auth:** requests need `Authorization: Bearer <FEEDBACK_API_TOKEN>`
  (at least 32 characters, compared in constant time). The service checks the
  token before it reads the body.
- **Input:** the body must have exactly `kind` (`bug` | `feature`), `title`,
  and optionally `description`, `app_version` and `platform`. Unknown fields
  are rejected. The client cannot choose labels, assignees or anything else.
  - The title is collapsed to one line of at most 120 characters.
  - The description is capped at 4000 characters.
  - Control and bidi-override characters are stripped.
  - `@mentions` are defused, so a report can never notify anyone.
  - Bodies over 24 KiB are refused.
- **Rate limit:** 5 reports in a burst, then one every 2 minutes. If the API
  token leaks, it is still worth at most about 30 issues per hour.
- **Errors:** GitHub failures are logged on the server and returned to the
  client only as a generic `502 upstream_failed`. Report text is never logged.

Because `Ymit24/squiggle` is public, submitted issues are public too.

## API

| Method | Path          | Auth | Result |
| ------ | ------------- | ---- | ------ |
| GET    | `/healthz`    | no   | `200 ok` |
| GET    | `/v1/auth`    | yes  | `204` if the token is valid (used by the app's "Test connection") |
| POST   | `/v1/reports` | yes  | `201 {"number": 12, "url": "https://github.com/..."}` |

```sh
curl -H "Authorization: Bearer $FEEDBACK_API_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"kind":"bug","title":"Crash on save","description":"Steps...","app_version":"0.2.34+77","platform":"linux"}' \
     https://<host>/v1/reports
```

Errors return `{"error": "<code>", "message": "<human readable>"}` with one
of these status codes:

- `401 unauthorized`
- `400 invalid_body`
- `413 too_large`
- `422 title_empty`, `title_too_long`, `description_too_long` or `invalid_app_version`
- `429 rate_limited` (with a `Retry-After` header)
- `502 upstream_failed`

## Configuration

The service reads its configuration from environment variables. See
[`.env.example`](.env.example).

| Variable | Default | |
| --- | --- | --- |
| `FEEDBACK_API_TOKEN` | required | Shared secret for clients |
| `FEEDBACK_GITHUB_TOKEN` | required | Fine-grained PAT (Issues: read/write, one repo) |
| `FEEDBACK_GITHUB_REPO` | required | `owner/name` |
| `FEEDBACK_BIND` | `127.0.0.1:8787` | Listen address |
| `FEEDBACK_LABEL` | `app-submission` | Created at startup if it does not exist |
| `RUST_LOG` | `info` | Log filter |

## Deploying on the devbox

1. **Create the GitHub token.** In GitHub → Settings → Developer settings →
   Fine-grained tokens, set:
   - Repository access: *Only select repositories* → `Ymit24/squiggle`
   - Permissions: *Issues* → *Read and write* (nothing else)
2. **Build and install the service:**

   ```sh
   cd services/feedback_api
   cargo build --release
   install -Dm755 target/release/squiggle-feedback-api ~/.local/bin/squiggle-feedback-api
   install -Dm600 .env.example ~/.config/squiggle-feedback-api/env
   $EDITOR ~/.config/squiggle-feedback-api/env   # add the PAT and `openssl rand -hex 32`
   install -Dm644 deploy/squiggle-feedback-api.service ~/.config/systemd/user/squiggle-feedback-api.service
   systemctl --user daemon-reload
   systemctl --user enable --now squiggle-feedback-api
   journalctl --user -u squiggle-feedback-api -f
   ```

3. **Expose it publicly with Tailscale Funnel.** The service only listens on
   localhost. Funnel puts it on the internet over HTTPS at the machine's
   `*.ts.net` name, so a computer that isn't on the tailnet can reach it:

   ```sh
   tailscale funnel --bg 8787
   # → https://devbox.<tailnet>.ts.net/  →  http://127.0.0.1:8787
   ```

   Funnel must be allowed for the node in the tailnet policy. The first run
   prints a link to enable it. Use `tailscale funnel status` to check it and
   `tailscale funnel --https=443 off` to remove it.
4. **Point the app at it.** In Squiggle, open **Report** → **Connection
   settings** and enter the HTTPS URL and the API token, then click **Test
   connection**.

## Development

```sh
cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test
```

The tests replace GitHub with a fake `IssueTracker`. To try the real HTTP
path locally, point `FEEDBACK_GITHUB_API` at a stub server.
