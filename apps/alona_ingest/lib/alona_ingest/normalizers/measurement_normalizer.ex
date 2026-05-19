defmodule AlonaIngest.Normalizers.MeasurementNormalizer do
  @moduledoc """
  legacy hook name; delegates to `AlonaIngest.Ingest.parse/1` (envelope decode + `Telemetry.Envelope.parse/1`).

  prefer `AlonaIngest.Ingest.ingest/1` for persistence.
  """

  def normalize(payload), do: AlonaIngest.Ingest.parse(payload)
end
