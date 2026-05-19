defmodule AlonaIngest.Adapters.Esp32Adapter do
  @moduledoc """
  ESP32 gateway payload adapter: device JSON → v1 envelope maps.

  Expects payloads published by an ESP32 gateway (ESP-NOW → MQTT/JSON). Each mappable
  entry in `readings` becomes one envelope for `AlonaIngest.Telemetry.Envelope.parse/1`.

  ## Input (version 1)

      {
        "version": 1,
        "device_id": "living-room-node-01",
        "measured_at": "2026-05-19T19:30:00Z",
        "readings": {
          "temperature_c": 22.4,
          "relative_humidity_pct": 58.1
        },
        "battery_mv": 4120,
        "rssi_dbm": -67
      }

  MVP reading → stream slug mapping is fixed in `@reading_slugs` (living room env streams).
  `device_id` is stored in envelope `raw` only; routing by device is not implemented yet.
  """

  @payload_version 1

  @reading_slugs %{
    "temperature_c" => "env_living_temp_c",
    "relative_humidity_pct" => "env_living_rh"
  }

  @spec normalize(map() | binary()) :: {:ok, [map()]} | {:error, atom()}
  def normalize(payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, map} when is_map(map) -> normalize(map)
      _ -> {:error, :invalid_json}
    end
  end

  def normalize(payload) when is_map(payload) do
    with :ok <- validate_version(payload),
         {:ok, device_id} <- require_string(payload, "device_id"),
         {:ok, readings} <- require_map(payload, "readings"),
         measured_at <- optional_string(payload, "measured_at"),
         device_meta <- device_meta(payload, device_id) do
      build_envelopes(readings, measured_at, device_meta)
    else
      {:error, :invalid_payload} -> {:error, :invalid_payload}
      {:error, reason} -> {:error, reason}
    end
  end

  def normalize(_), do: {:error, :invalid_payload}

  defp validate_version(payload) do
    if get(payload, "version") == @payload_version do
      :ok
    else
      {:error, :unsupported_version}
    end
  end

  defp require_string(payload, key) do
    case get(payload, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :invalid_payload}
    end
  end

  defp require_map(payload, key) do
    case get(payload, key) do
      value when is_map(value) -> {:ok, value}
      _ -> {:error, :invalid_payload}
    end
  end

  defp optional_string(payload, key) do
    case get(payload, key) do
      value when is_binary(value) and value != "" -> value
      _ -> nil
    end
  end

  defp device_meta(payload, device_id) do
    %{
      "adapter" => "esp32",
      "device_id" => device_id,
      "payload_version" => @payload_version
    }
    |> maybe_put_raw("battery_mv", get(payload, "battery_mv"))
    |> maybe_put_raw("rssi_dbm", get(payload, "rssi_dbm"))
  end

  defp maybe_put_raw(meta, _key, nil), do: meta
  defp maybe_put_raw(meta, _key, value) when not is_number(value), do: meta
  defp maybe_put_raw(meta, key, value), do: Map.put(meta, key, value)

  defp build_envelopes(readings, measured_at, device_meta) do
    envelopes =
      readings
      |> Enum.sort_by(fn {key, _} -> to_string(key) end)
      |> Enum.reduce([], fn {reading_key, value}, acc ->
        reading = to_string(reading_key)

        case Map.get(@reading_slugs, reading) do
          nil ->
            acc

          stream_slug when is_number(value) ->
            raw =
              device_meta
              |> Map.put("reading", reading)

            envelope =
              %{
                "stream_slug" => stream_slug,
                "value" => value,
                "raw" => raw
              }
              |> maybe_put_measured_at(measured_at)

            [envelope | acc]

          _ ->
            acc
        end
      end)
      |> Enum.reverse()

    if envelopes == [] do
      {:error, :no_mappable_readings}
    else
      {:ok, envelopes}
    end
  end

  defp maybe_put_measured_at(envelope, nil), do: envelope
  defp maybe_put_measured_at(envelope, measured_at), do: Map.put(envelope, "measured_at", measured_at)

  defp get(map, key) when is_binary(key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, String.to_existing_atom(key))
    end
  rescue
    ArgumentError -> nil
  end
end
