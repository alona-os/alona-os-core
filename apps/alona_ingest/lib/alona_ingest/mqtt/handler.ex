defmodule AlonaIngest.Mqtt.Handler do
  @moduledoc false

  use Tortoise311.Handler
  require Logger

  alias AlonaIngest.Mqtt.TopicRouter

  @impl Tortoise311.Handler
  def handle_message(topic_levels, payload, state) do
    topic = Enum.join(topic_levels, "/")
    payload_binary = mqtt_payload(payload)

    case TopicRouter.route(topic, payload_binary) do
      {:ok, :ignored} ->
        Logger.debug("mqtt ingest ignored topic=#{topic}")

      {:ok, :ingested} ->
        :ok

      {:error, {:partial_ingest_failed, failures}} ->
        Logger.warning(
          "mqtt partial ingest topic=#{topic} failures=#{inspect(failures)}"
        )

      {:error, reason} ->
        Logger.warning("mqtt ingest failed topic=#{topic} reason=#{inspect(reason)}")
    end

    {:ok, state}
  end

  defp mqtt_payload(nil), do: <<>>
  defp mqtt_payload(binary) when is_binary(binary), do: binary

end
