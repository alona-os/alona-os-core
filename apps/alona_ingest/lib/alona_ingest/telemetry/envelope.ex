defmodule AlonaIngest.Telemetry.Envelope do
  @moduledoc """
  v1 internal telemetry envelope: JSON or map → `AlonaCore.Telemetry.Point`.

  ## Envelope v1 (JSON object)

      {
        "stream_slug": "env_living_temp_c",
        "value": 23.4,
        "measured_at": "2026-05-19T18:00:00Z",
        "quality": 100,
        "property_slug": "default-site",
        "raw": {"source": "test"}
      }

  - `stream_slug` — required non-empty string
  - `value` — required number (maps to `value_number`)
  - `measured_at` — optional ISO-8601 UTC; omitted → `DateTime.utc_now(:microsecond)` in the parser
  - `quality` — optional integer 0..100; omitted → `100`
  - `property_slug` — optional; omitted → core default property (`default-site`)
  - `raw` — optional object → `raw_payload`

  Transport layers (MQTT, HTTP, etc.) should decode bytes to a map and call `parse/1`,
  or pass JSON directly to `AlonaIngest.Ingest.ingest/1`.
  """

  alias AlonaCore.Telemetry.Point

  @default_quality 100

  @spec decode(binary()) :: {:ok, map()} | {:error, :invalid_json}
  def decode(payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, map} when is_map(map) -> {:ok, map}
      _ -> {:error, :invalid_json}
    end
  end

  @spec parse(map()) :: {:ok, Point.t()} | {:error, atom()}
  def parse(envelope) when is_map(envelope) do
    with {:ok, stream_slug} <- require_string(envelope, "stream_slug"),
         {:ok, value_number} <- require_number(envelope, "value"),
         {:ok, measured_at} <- optional_measured_at(envelope),
         {:ok, quality} <- optional_quality(envelope),
         {:ok, property_slug} <- optional_string(envelope, "property_slug"),
         {:ok, raw_payload} <- optional_raw(envelope) do
      attrs = %{
        stream_slug: stream_slug,
        value_number: value_number,
        measured_at: measured_at,
        quality: quality,
        property_slug: property_slug,
        raw_payload: raw_payload
      }

      Point.new(attrs)
    end
  end

  def parse(_), do: {:error, :invalid_envelope}

  defp require_string(map, key) do
    case Map.get(map, key) do
      slug when is_binary(slug) and slug != "" -> {:ok, slug}
      _ -> {:error, :invalid_envelope}
    end
  end

  defp require_number(map, key) do
    case Map.get(map, key) do
      value when is_number(value) -> {:ok, value}
      _ -> {:error, :invalid_envelope}
    end
  end

  defp optional_string(map, key) do
    case Map.get(map, key) do
      nil -> {:ok, nil}
      slug when is_binary(slug) and slug != "" -> {:ok, slug}
      _ -> {:error, :invalid_envelope}
    end
  end

  defp optional_measured_at(map) do
    case Map.get(map, "measured_at") do
      nil ->
        {:ok, DateTime.utc_now(:microsecond)}

      iso when is_binary(iso) ->
        case DateTime.from_iso8601(iso) do
          {:ok, dt, _offset} -> {:ok, dt}
          _ -> {:error, :invalid_measured_at}
        end

      _ ->
        {:error, :invalid_measured_at}
    end
  end

  defp optional_quality(map) do
    case Map.get(map, "quality") do
      nil ->
        {:ok, @default_quality}

      quality when is_integer(quality) and quality >= 0 and quality <= 100 ->
        {:ok, quality}

      _ ->
        {:error, :invalid_quality}
    end
  end

  defp optional_raw(map) do
    case Map.get(map, "raw") do
      nil -> {:ok, %{}}
      raw when is_map(raw) -> {:ok, raw}
      _ -> {:error, :invalid_envelope}
    end
  end
end
