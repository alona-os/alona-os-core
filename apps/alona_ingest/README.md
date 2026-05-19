# AlonaIngest

Telemetry ingestion for measurements: **v1 envelope** parsing and MQTT transport (`tortoise311`) for ESP32 payloads.

Envelope path: MQTT bytes → adapters → [`AlonaIngest.Ingest.ingest/1`](lib/alona_ingest/ingest.ex) → `AlonaCore.Measurements.ingest_point/1`.

## Configuration

Defaults live in [`config/config.exs`](../../config/config.exs); non-test overlays use [`config/mqtt_runtime.exs`](../../config/mqtt_runtime.exs) (loaded after `dev.exs` / `prod.exs`). Tests set `enabled: false` in [`config/test.exs`](../../config/test.exs).

Environment variables (`ALONA_MQTT_*`): see [`alona-os-infra/env/alona.env.example`](../../../alona-os-infra/env/alona.env.example).

| Variable | Purpose |
|---------|---------|
| `ALONA_MQTT_ENABLED` | `false`/`0` disables the supervised connection |
| `ALONA_MQTT_HOST` | Broker hostname |
| `ALONA_MQTT_PORT` | Broker TCP port |
| `ALONA_MQTT_TOPICS` | Comma-separated topic filters (default includes `alona/esp32/living-room/telemetry`) |
| `ALONA_MQTT_CLIENT_ID` | MQTT client id (default `alona-ingest`) |
| `ALONA_MQTT_USERNAME` / `ALONA_MQTT_PASSWORD` | Optional broker auth |

## Running with Mosquitto (manual check)

Requires Postgres seeded (`./setup.sh` or `mix ecto.seed`) so `env_living_temp_c` and `env_living_rh` streams exist.

1. Run a broker on `${ALONA_MQTT_HOST:-localhost}` port `${ALONA_MQTT_PORT:-1883}` (anonymous clients OK for LAN dev).
2. From `alona-os-core/`: `mix phx.server` (`alona_ingest` starts with the umbrella via `alona_ui`; use `ALONA_MQTT_ENABLED=false` to skip MQTT).
3. Publish gateway-style JSON:

```bash
mosquitto_pub -h localhost -p 1883 \
  -t 'alona/esp32/living-room/telemetry' \
  -m '{"version":1,"device_id":"living-room-node-01","measured_at":"2026-05-19T19:30:00Z","readings":{"temperature_c":22.4,"relative_humidity_pct":58.1}}'
```

LiveViews that subscribe to `AlonaCore.Broadcast` (e.g. `/`, `/environment`) should refresh from updated `current_values`.
