defmodule AlonaIngest.Mqtt.Client do
  @moduledoc """
  Builds `Tortoise311.Connection` child spec from `Application` config.

  MQTT settings merge `config/*.exs` with `mqtt_runtime.exs` (non-test environments).
  """

  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(_arg \\ []) do
    conn_kw = connection_opts()

    Tortoise311.Connection.child_spec(conn_kw)
    |> Supervisor.child_spec(%{
      id: {:alona_mqtt, Keyword.fetch!(conn_kw, :client_id)},
      restart: :permanent
    })
  end

  @spec connection_opts() :: keyword()
  def connection_opts do
    cfg = Application.fetch_env!(:alona_ingest, __MODULE__)

    client_id = Keyword.fetch!(cfg, :client_id)
    host = Keyword.fetch!(cfg, :host)
    port = Keyword.fetch!(cfg, :port)
    topics = Keyword.fetch!(cfg, :topics)

    subs = Enum.map(topics, fn t -> {t, 0} end)

    kw = [
      client_id: client_id,
      server: {Tortoise311.Transport.Tcp, host: host, port: port},
      subscriptions: subs,
      handler: {AlonaIngest.Mqtt.Handler, []}
    ]

    user_name = Keyword.get(cfg, :user_name)

    kw
    |> maybe_put_keyword(:user_name, user_name)
    |> maybe_put_keyword(:password, Keyword.get(cfg, :password))
  end

  defp maybe_put_keyword(kw, _key, nil), do: kw
  defp maybe_put_keyword(kw, key, value), do: Keyword.put(kw, key, value)

end
