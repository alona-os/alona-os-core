import Config

enabled =
  case System.get_env("ALONA_MQTT_ENABLED") do
    v when v in ~w(false 0) -> false
    v when v in ~w(true 1) -> true
    _ -> true
  end

host = System.get_env("ALONA_MQTT_HOST", "localhost")
port_env = System.get_env("ALONA_MQTT_PORT", "1883")
port = String.to_integer(port_env)

default_topics = ["alona/esp32/living-room/telemetry"]

topics =
  case System.get_env("ALONA_MQTT_TOPICS") do
    nil ->
      default_topics

    csv ->
      csv
      |> String.split(",", trim: true)
      |> Enum.reject(&(&1 == ""))
      |> then(fn list ->
        if list == [], do: default_topics, else: list
      end)
  end

client_id = System.get_env("ALONA_MQTT_CLIENT_ID", "alona-ingest")

user_name =
  System.get_env("ALONA_MQTT_USERNAME") |> then(&if(&1 in [nil, ""], do: nil, else: &1))

password =
  System.get_env("ALONA_MQTT_PASSWORD") |> then(&if(&1 in [nil, ""], do: nil, else: &1))

config :alona_ingest, AlonaIngest.Mqtt.Client,
  enabled: enabled,
  host: host,
  port: port,
  topics: topics,
  client_id: client_id,
  user_name: user_name,
  password: password
