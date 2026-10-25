# Porkbun DNS Updater
## A simple script to keep Porkbun DNS A records pointed at your public IP

### How it works
Every **INTERVAL** seconds the updater looks up your public IPv4 address, then reconciles the A records for each entry in **SUB_DOMAINS**:

* **Update** – existing A records whose IP differs are pointed at the current IP.
* **Create** – subdomains with no A record get one (disable with `CREATE_RECORDS=false`).
* **Delete** – A records the updater manages that are no longer listed in **SUB_DOMAINS** are removed (disable with `DELETE_RECORDS=false`).

Records the updater creates or updates are tagged in their Porkbun **notes** with `[managed-by:porkbun-dns-updater]`, and any existing notes are kept. Only tagged records are ever deleted, so records you add by hand are never removed. A record listed in **SUB_DOMAINS** is adopted (tagged) on the first run, and from then on removing it from the list deletes it. If you run more than one updater against the same domain, give each a different **MANAGED_TAG** so they don't delete each other's records.

Try `DRY_RUN=true` first to see what would change; Porkbun validates each write without applying it.

### Porkbun setup
* Enable **API Access** for the domain in the Porkbun dashboard.
* Create an API key with at least the `read` and `dns` permissions, ideally restricted to this domain. The updater checks the key and its permissions at startup.
* Writes are accepted even if the domain is not using Porkbun's nameservers, but they won't change what resolves. Porkbun's warnings about this are logged.

### Configuration
| Variable | Default | Description |
|---|---|---|
| `DOMAIN` | *(required)* | Domain to manage, e.g. `example.com` |
| `API_KEY` / `API_SECRET` | *(required)* | Porkbun API credentials. `API_KEY_FILE` / `API_SECRET_FILE` read them from files instead (Docker secrets) |
| `SUB_DOMAINS` | `@` | Comma-delimited subdomains, e.g. `@,www,api,*`. `@` is the apex. Omit the domain itself |
| `INTERVAL` | `600` | Seconds between checks (minimum 60) |
| `TTL` | `600` | TTL for created records |
| `CREATE_RECORDS` | `true` | Create missing A records |
| `DELETE_RECORDS` | `true` | Delete managed A records no longer in `SUB_DOMAINS` |
| `MANAGED_TAG` | `porkbun-dns-updater` | Ownership tag written to record notes |
| `DRY_RUN` | `false` | Validate changes with Porkbun without applying them |
| `RUN_ONCE` | `false` | Run a single check and exit non-zero on failure (Kubernetes CronJob, cron) |
| `LOG_FORMAT` | `text` | `json` writes one JSON object per line with an `event` field, for Loki |
| `LOG_LEVEL` | `info` | `debug` also logs records that need no change |
| `PUSHGATEWAY_URL` | | Push per-run metrics to a Prometheus Pushgateway, e.g. `http://pushgateway:9091` |
| `IP_URLS` | Porkbun IPv4 `/ip`, ipify, icanhazip | Space-separated IP lookup URLs, tried in order |

The public IP comes from Porkbun's IPv4-only `/ip` endpoint, falling back to ipify and icanhazip. Private, CGNAT and malformed addresses are rejected.

Transient failures (network errors, HTTP 429/5xx) are retried with backoff, and Porkbun's `Retry-After` is respected.

### Monitoring
**Logs.** With `LOG_FORMAT=json` every line has `ts`, `level`, `msg`, `domain` and an `event`:

| `event` | Meaning |
|---|---|
| `record_created`, `record_updated`, `record_deleted`, `record_adopted` | A record changed (`fqdn`, `old_ip`, `new_ip`) |
| `record_error` | A create/update/delete failed (`action`, `error`, `error_code`) |
| `porkbun_warning` | Porkbun accepted a write but warned, e.g. the domain is not delegated to Porkbun, so nothing resolvable changed |
| `check_completed` | End of a check: `status` (`success`/`failure`), per-action counts, `duration_seconds` |
| `api_retry`, `ip_lookup_failed`, `fatal`, `config_error` | Retries and failures |

For example, in Loki: `{container="porkbun-dns-updater"} | json | event=~"record_(created|updated|deleted)"`.

**Kubernetes.** Run it as a CronJob with `RUN_ONCE=true`, so each run exits non-zero on failure. kube-state-metrics then exposes success and failure with no custom metrics. [`deploy/kubernetes/`](deploy/kubernetes) has a CronJob, `PrometheusRule` alerts built on those metrics, and Loki ruler examples for record-level alerts.

**Metrics.** If `PUSHGATEWAY_URL` is set, each check pushes these metrics, labelled by `domain`:
* `porkbun_dns_updater_last_run_success`
* `porkbun_dns_updater_last_success_timestamp_seconds`
* `porkbun_dns_updater_last_run_duration_seconds`
* `porkbun_dns_updater_records{action}`
* `porkbun_dns_updater_public_ip_info{ip}`

**Docker.** In loop mode the image's `HEALTHCHECK` reports unhealthy if no check has succeeded within about 3 intervals.

### Releases
* The image is published for `amd64`, `arm64` and `arm/v7` as both `:latest` and `:<version>`, where `<version>` is the contents of the `VERSION` file at repo root. Bump `VERSION` in a PR and merge to `main` to publish a new immutable tag.

## Docker run example
```
docker run -d \
  --name=porkbun-dns-updater \
  -e DOMAIN=example.com \
  -e SUB_DOMAINS='@,www,api' \
  -e API_KEY='pk1_xxxxxxx' \
  -e API_SECRET='sk1_xxxxxxx' \
  -e INTERVAL=600 \
  --restart unless-stopped \
  dmleet/porkbun-dns-updater:latest
```

## Kubernetes example
```
kubectl create secret generic porkbun-dns-updater \
  --from-literal=api-key=pk1_xxxxxxx --from-literal=api-secret=sk1_xxxxxxx
# edit DOMAIN / SUB_DOMAINS first
kubectl apply -f deploy/kubernetes/cronjob.yaml -f deploy/kubernetes/prometheus-rules.yaml
```
