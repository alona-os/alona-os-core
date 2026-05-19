defmodule AlonaIngest.Mqtt.TopicRouter do
  @moduledoc """
  MVP routing: subscribed Living Room ESP32 MQTT topic → `Esp32Adapter` → `Ingest.ingest/1`.
  """

  alias AlonaIngest.Adapters.Esp32Adapter
  alias AlonaIngest.Ingest

  @type route_result ::
          {:ok, :ignored}
          | {:ok, :ingested}
          | {:error, atom()}
          | {:error, {:partial_ingest_failed, list({String.t(), atom})}}

  @spec route(topic :: String.t(), payload :: nil | binary()) :: route_result()
  def route(topic, payload) when is_binary(topic) do
    if topic in configured_topics() do
      ingest_living_room_esp32(payload)
    else
      {:ok, :ignored}
    end
  end

  defp ingest_living_room_esp32(payload) do
    case Esp32Adapter.normalize(payload) do
      {:ok, envelopes} -> ingest_envelopes(envelopes)
      {:error, reason} -> {:error, reason}
    end
  end

  defp ingest_envelopes(envelopes) do
    results =
      Enum.map(envelopes, fn envelope ->
        slug = envelope["stream_slug"]

        case Ingest.ingest(envelope) do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, {slug || "", reason}}
        end
      end)

    failures =
      results
      |> Enum.filter(&match?({:error, _}, &1))
      |> Enum.map(fn {:error, failure} -> failure end)

    if failures == [] do
      {:ok, :ingested}
    else
      {:error, {:partial_ingest_failed, failures}}
    end
  end

  defp configured_topics do
    :alona_ingest
    |> Application.fetch_env!(AlonaIngest.Mqtt.Client)
    |> Keyword.fetch!(:topics)
  end
end
