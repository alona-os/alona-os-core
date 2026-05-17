# Alona OS — Core (umbrella)

Elixir umbrella: **`alona_core`** (domains + Postgres), **`alona_ui`** (Phoenix LiveView shell), **`alona_ingest`** (MQTT/ingestion stubs).

## Requirements

- **Elixir** 1.15+ and **Erlang/OTP** (see `mix.exs` in each app)
- **PostgreSQL** running at **`localhost:5432`** (or set `PG_PORT` for `./setup.sh` and edit `config/dev.exs`). The script probes the port when `pg_isready` or `nc` is available.
- Default dev credentials (`config/dev.exs`): username **`postgres`**, password **`postgres`**, database **`alona_os_core_dev`**. Change that file if your Postgres differs.

## Quick start

From this directory (`alona-os-core/`):

```bash
chmod +x setup.sh   # first time only
./setup.sh
mix phx.server
```

Then open [http://localhost:4000](http://localhost:4000).

## `./setup.sh`

Runs:

1. `mix deps.get` — umbrella dependencies  
2. `mix setup` in `apps/alona_ui` — Tailwind + esbuild installers and asset build hooks  
3. **`mix ecto.setup`** — `ecto.create`, `ecto.migrate`, then `mix ecto.seed` (skipped if `SKIP_DATABASE=1`)

The script exits on the first failing step (`set -e`).

Environment overrides:

| Variable | Meaning |
|----------|---------|
| `SKIP_DATABASE=1` | Skip `mix ecto.setup` (only deps + UI assets). Run `mix ecto.setup` yourself after Postgres is up. |
| `PG_PORT` | Port to probe before migrate (defaults to **5432**). Example: `PG_PORT=5433 ./setup.sh` |

## Manual setup (same as the script)

```bash
mix deps.get
(cd apps/alona_ui && mix setup)
mix ecto.setup
```

## Useful commands

| Command | Purpose |
|--------|---------|
| `mix phx.server` | Run the Phoenix server (`:alona_ui`) |
| `mix ecto.seed` | Re-run seeds only |
| `mix test` | Run tests for all umbrella apps |

## Troubleshooting

- **`connection refused` on `localhost:5432`** — Postgres is not listening. Start it (Docker, Homebrew `brew services start postgresql@…`, Postgres.app, etc.), confirm `pg_isready -h localhost -p 5432` or retry `./setup.sh`. Until then use `SKIP_DATABASE=1 ./setup.sh` plus `mix ecto.setup` later.
- **Other `ecto.setup` / DB errors** — align host, port, user, and password with `config/dev.exs`. Retry `mix ecto.create`, `mix ecto.migrate`, then `mix ecto.seed`.
- **Asset / Tailwind errors** — from `apps/alona_ui/` run `mix setup` or `mix assets.setup` then `mix assets.build`.
- **`Could not resolve "phoenix-colocated/alona_ui"`** — LiveView writes that tree under `_build/<env>/phoenix-colocated/`. Umbrella `config/config.exs` joins `Mix.Project.build_path()` into esbuild `NODE_PATH` so it resolves; run `mix compile` before assets. If this still breaks after renaming apps, remove stale `_build/<env>/phoenix-colocated/*` and recompile.
