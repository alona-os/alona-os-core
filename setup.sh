#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PG_PORT="${PG_PORT:-5432}"

# 0 = reachable, 1 = checked but not reachable, 2 = cannot check (missing pg_isready and nc)
postgres_listening_status() {
  if command -v pg_isready >/dev/null 2>&1; then
    pg_isready -h localhost -p "$PG_PORT" -q 2>/dev/null
    return $?
  fi

  if command -v nc >/dev/null 2>&1; then
    nc -z localhost "$PG_PORT" 2>/dev/null
    return $?
  fi

  return 2
}

require_postgres() {
  cat >&2 <<EOF

PostgreSQL is not accepting TCP connections at localhost:${PG_PORT} (nothing listening yet).

Before \`mix ecto.setup\`:
  • Start Postgres, then rerun ./setup.sh — or run only \`mix ecto.setup\` once the server is up.
  • Homebrew (version may vary): brew services start postgresql@16
  • Postgres.app: start the cluster from the menu-bar app.
  • Docker:

    docker run -d --name alona-postgres -p ${PG_PORT}:5432 \\
      -e POSTGRES_PASSWORD=postgres postgres:16

Match user/password/host in config/dev.exs (default postgres / postgres on localhost).

Only deps + assets, no DB: SKIP_DATABASE=1 ./setup.sh
Different port (e.g. Postgres on 5433): PG_PORT=5433 ./setup.sh

EOF

  exit 1
}

echo "==> Installing Elixir umbrella dependencies"
mix deps.get

echo "==> UI app (alona_ui): Tailwind/esbuild installers + asset setup"
(cd apps/alona_ui && mix setup)

if [[ "${SKIP_DATABASE:-}" == "1" ]]; then
  echo "==> SKIP_DATABASE=1 — skipping create / migrate / seed"
else
  postgres_listening_status
  rc="${?}"

  case "$rc" in
    1)
      require_postgres
      ;;
    2)
      echo >&2 "==> Warning: install pg_isready (PostgreSQL client) or nc to verify Postgres before migrate." >&2
      echo >&2 "    Continuing; if migrate fails, start Postgres then run: mix ecto.setup" >&2
      ;;
  esac

  echo "==> Database: create, migrate, seed"
  mix ecto.setup
fi

echo "==> Done. Start the server with: mix phx.server"
