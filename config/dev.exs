import Config

# homebrew / local postgres often has no `postgres` role; default to your login (or PGUSER).
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
  database: "alona_os_core_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :alona_ui, AlonaUiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "4agKcC/5fyvlJach4w2eJxVXlLSMITkXFL+HttKiNdPv0UrZhhVFBrwuFcZx6Yxe",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:alona_ui, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:alona_ui, ~w(--watch)]}
  ]

config :alona_ui, AlonaUiWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$"E,
      ~r"priv/gettext/.*\.po$"E,
      ~r"lib/alona_ui_web/router\.ex$"E,
      ~r"lib/alona_ui_web/(controllers|live|components)/.*\.(ex|heex)$"E
    ]
  ]

config :alona_ui, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
