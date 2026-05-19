defmodule AlonaIngest.Ingest do
  @moduledoc """
  Ingest boundary: telemetry payload → `AlonaCore.Telemetry.Point` → `Measurements.ingest_point/1`.

  ## Examples (IEx, after DB is up)

      alias AlonaIngest.Ingest

      Ingest.ingest(%{
        "stream_slug" => "env_living_temp_c",
        "value" => 23.4,
        "property_slug" => "default-site"
      })

      Ingest.ingest(~s|{"stream_slug":"env_living_temp_c","value":23.4}|)

  MQTT and other transports should decode to a map or JSON string and call `ingest/1`.
  """

  alias AlonaCore.Measurements
  alias AlonaIngest.Telemetry.Envelope

  @spec parse(map() | binary()) :: {:ok, AlonaCore.Telemetry.Point.t()} | {:error, atom()}
  def parse(payload) when is_map(payload), do: Envelope.parse(payload)

  def parse(payload) when is_binary(payload) do
    with {:ok, map} <- Envelope.decode(payload), do: Envelope.parse(map)
  end

  def parse(_), do: {:error, :invalid_envelope}

  @spec ingest(map() | binary()) ::
          {:ok, %{measurement: map(), current_value: map()}} | {:error, atom()}
  def ingest(payload) do
    with {:ok, point} <- parse(payload), do: Measurements.ingest_point(point)
  end
end
