defmodule AlonaIngest.Mqtt.TopicRouter do
  @moduledoc """
  placeholder for MQTT topic routing to normalizers/adapters.
  """

  def route(_topic, _payload), do: {:ok, :ignored}
end
