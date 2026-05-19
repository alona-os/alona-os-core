import Config

config :alona_core,
  ecto_repos: [AlonaCore.Repo],
  generators: [timestamp_type: :utc_datetime_usec]

config :alona_ui,
  generators: [timestamp_type: :utc_datetime_usec]

# shared pubsub for core writes and LiveView subscriptions
config :alona_ui, AlonaUiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AlonaUiWeb.ErrorHTML, json: AlonaUiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AlonaCore.PubSub,
  live_view: [signing_salt: "p3wnZSUa"]

config :esbuild,
  version: "0.25.4",
  alona_ui: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/alona_ui/assets", __DIR__),
    env: %{
      "NODE_PATH" => [
        Path.expand("../deps", __DIR__),
        Mix.Project.build_path()
      ]
    }
  ]

config :tailwind,
  version: "4.1.12",
  alona_ui: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/alona_ui", __DIR__)
  ]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :alona_ingest, AlonaIngest.Mqtt.Client,
  enabled: true,
  host: "localhost",
  port: 1883,
  topics: ["alona/esp32/living-room/telemetry"],
  client_id: "alona-ingest",
  user_name: nil,
  password: nil

import_config "#{config_env()}.exs"

if config_env() in [:dev, :prod] do
  import_config "mqtt_runtime.exs"
end
