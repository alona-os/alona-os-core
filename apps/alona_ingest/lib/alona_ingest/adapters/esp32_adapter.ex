defmodule AlonaIngest.Adapters.Esp32Adapter do
  @moduledoc """
  future ESP32 payload adapter.
  """

  def normalize(_payload), do: {:error, :not_implemented}
end
