defmodule AlonaIngest do
  @moduledoc """
  Telemetry ingestion for Alona OS.

  Entry point: `AlonaIngest.Ingest.ingest/1` — accepts a v1 envelope map or JSON string,
  normalizes to `AlonaCore.Telemetry.Point`, and persists via `AlonaCore.Measurements.ingest_point/1`.

  See `AlonaIngest.Telemetry.Envelope` for the v1 wire format.
  """

  defdelegate ingest(payload), to: AlonaIngest.Ingest
  defdelegate parse(payload), to: AlonaIngest.Ingest
end
