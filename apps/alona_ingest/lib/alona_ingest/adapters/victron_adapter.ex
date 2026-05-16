defmodule AlonaIngest.Adapters.VictronAdapter do
  @moduledoc """
  future Victron GX integration adapter.
  """

  def normalize(_payload), do: {:error, :not_implemented}
end
