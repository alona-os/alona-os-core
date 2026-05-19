defmodule AlonaIngest.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if mqtt_enabled?() do
        [AlonaIngest.Mqtt.Client.child_spec([])]
      else
        []
      end

    opts = [strategy: :one_for_one, name: AlonaIngest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp mqtt_enabled? do
    case Application.fetch_env(:alona_ingest, AlonaIngest.Mqtt.Client) do
      {:ok, config} ->
        Keyword.get(config, :enabled, false) == true

      :error ->
        false
    end
  end
end
