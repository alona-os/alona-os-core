import Config

repo_username =
  System.get_env("DATABASE_USERNAME") ||
    System.get_env("PGUSER") ||
    System.get_env("USER") ||
    "postgres"

repo_password = System.get_env("DATABASE_PASSWORD") || System.get_env("PGPASSWORD") || ""
repo_hostname = System.get_env("DATABASE_HOST") || System.get_env("PGHOST") || "localhost"

config :alona_core, AlonaCore.Repo,
  username: repo_username,
  password: repo_password,
  hostname: repo_hostname,
  database: "alona_os_core_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :alona_ui, AlonaUiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "w8FFTWbDG89bzIUw6AAPeuTqVjSIy6lh7KK8lt0w56hMYmjzHHA+mrNU4LiCzwqU",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :phoenix, sort_verified_routes_query_params: true

config :alona_ingest, AlonaIngest.Mqtt.Client, enabled: false
