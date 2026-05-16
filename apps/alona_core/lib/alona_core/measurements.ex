defmodule AlonaCore.Measurements do
  @moduledoc """
  reads and writes for measurement streams + current dashboard cache rows.
  """
  import Ecto.Query
  alias AlonaCore.Repo
  alias AlonaCore.Broadcast

  alias AlonaCore.Measurements.{
    CurrentValue,
    Measurement,
    MeasurementStream,
    MetricDefinition
  }

  def streams_for_slugs(slugs) when is_list(slugs) do
    from(s in MeasurementStream,
      where: s.slug in ^slugs,
      preload: [:current_value, :metric, :subject_entity, :source_entity],
      order_by: s.slug
    )
    |> Repo.all()
  end

  def list_metric_definitions, do: Repo.all(from(m in MetricDefinition, order_by: m.name))

  def record_measurement_and_current!(attrs)
      when is_map(attrs) do
    Repo.transaction(fn ->
      stream_id = Map.fetch!(attrs, :stream_id)
      measured_at = Map.fetch!(attrs, :measured_at)

      measurement_attrs =
        Map.take(attrs, [:stream_id, :measured_at, :value_number, :value_text, :value_boolean, :quality, :raw_payload])

      {:ok, _} =
        %Measurement{}
        |> Measurement.changeset(measurement_attrs)
        |> Repo.insert()

      current =
        case Repo.get_by(CurrentValue, stream_id: stream_id) do
          nil ->
            struct(CurrentValue, stream_id: stream_id)

          cv ->
            cv
        end

      {:ok, _} =
        current
        |> CurrentValue.changeset(%{
          stream_id: stream_id,
          measured_at: measured_at,
          latest_value: Map.get(attrs, :value_number),
          latest_value_text: Map.get(attrs, :value_text),
          quality: Map.get(attrs, :quality)
        })
        |> Repo.insert_or_update()

      Broadcast.broadcast_dashboard()
      :ok
    end)
  end
end
