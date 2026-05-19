defmodule AlonaCore.Measurements do
  @moduledoc """
  reads and writes for measurement streams + current dashboard cache rows.
  """
  import Ecto.Query
  alias AlonaCore.Repo
  alias AlonaCore.Broadcast
  alias AlonaCore.Telemetry.Point
  alias AlonaCore.Topology
  alias AlonaCore.Topology.Property

  alias AlonaCore.Measurements.{
    CurrentValue,
    Measurement,
    MeasurementStream,
    MetricDefinition
  }

  @default_property_slug "default-site"

  def streams_for_slugs(slugs, opts \\ []) when is_list(slugs) do
    property_id = resolve_property_id!(opts)

    from(s in MeasurementStream,
      where: s.slug in ^slugs and s.property_id == ^property_id,
      preload: [:current_value, :metric, :subject_entity, :source_entity],
      order_by: s.slug
    )
    |> Repo.all()
  end

  def list_metric_definitions, do: Repo.all(from(m in MetricDefinition, order_by: m.name))

  @doc """
  ingests a single normalized telemetry point.
  """
  def ingest_point(%Point{} = point) do
    with {:ok, point} <- Point.new(Map.from_struct(point)),
         {:ok, property} <- resolve_property(point.property_slug),
         {:ok, stream} <- resolve_stream(property, point),
         :ok <- validate_stream_active(stream),
         :ok <- validate_value_type(stream, point),
         attrs <- Point.to_measurement_attrs(point, stream.id),
         {:ok, result} <- persist_measurement(attrs) do
      {:ok, result}
    end
  end

  def ingest_point(attrs) when is_map(attrs) do
    attrs
    |> then(&struct(Point, Map.take(&1, Map.keys(%Point{}))))
    |> ingest_point()
  end

  @doc """
  ingests multiple points. returns `{:ok, results}`, `{:partial, results}`, or `{:error, results}`.
  """
  def ingest_points(points) when is_list(points) do
    results = Enum.map(points, &ingest_point_result/1)

    cond do
      Enum.all?(results, &match?({:ok, _}, &1)) ->
        {:ok, results}

      Enum.all?(results, &match?({:error, _}, &1)) ->
        {:error, results}

      true ->
        {:partial, results}
    end
  end

  def record_measurement_and_current!(attrs) when is_map(attrs) do
    case persist_measurement(attrs) do
      {:ok, _} -> :ok
      {:error, reason} -> raise "failed to record measurement: #{inspect(reason)}"
    end
  end

  defp ingest_point_result(point) do
    case ingest_point(point) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  defp persist_measurement(attrs) when is_map(attrs) do
    Repo.transaction(fn ->
      stream_id = Map.fetch!(attrs, :stream_id)
      measured_at = Map.fetch!(attrs, :measured_at)

      measurement_attrs =
        Map.take(attrs, [
          :stream_id,
          :measured_at,
          :value_number,
          :value_text,
          :value_boolean,
          :quality,
          :raw_payload
        ])

      {:ok, measurement} =
        %Measurement{}
        |> Measurement.changeset(measurement_attrs)
        |> Repo.insert()

      current =
        case Repo.get_by(CurrentValue, stream_id: stream_id) do
          nil -> struct(CurrentValue, stream_id: stream_id)
          cv -> cv
        end

      {:ok, current_value} =
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

      %{measurement: measurement, current_value: current_value}
    end)
  end

  defp resolve_property(nil), do: Topology.default_property()
  defp resolve_property(slug) when is_binary(slug), do: Topology.get_property_by_slug(slug)

  defp resolve_stream(%Property{} = property, %Point{stream_id: id}) when is_integer(id) do
    case Repo.get_by(MeasurementStream, id: id, property_id: property.id) do
      %MeasurementStream{} = stream -> {:ok, Repo.preload(stream, :metric)}
      nil -> {:error, :stream_not_found}
    end
  end

  defp resolve_stream(%Property{} = property, %Point{stream_slug: slug}) when is_binary(slug) do
    case Repo.get_by(MeasurementStream, slug: slug, property_id: property.id) do
      %MeasurementStream{} = stream -> {:ok, Repo.preload(stream, :metric)}
      nil -> {:error, :stream_not_found}
    end
  end

  defp validate_stream_active(%MeasurementStream{is_active: true}), do: :ok
  defp validate_stream_active(%MeasurementStream{}), do: {:error, :inactive_stream}

  defp validate_value_type(%MeasurementStream{metric: %{value_type: "number"}}, %Point{value_number: n})
       when is_number(n),
       do: :ok

  defp validate_value_type(%MeasurementStream{metric: %{value_type: "string"}}, %Point{value_text: t})
       when is_binary(t),
       do: :ok

  defp validate_value_type(%MeasurementStream{metric: %{value_type: "boolean"}}, %Point{value_boolean: b})
       when is_boolean(b),
       do: :ok

  defp validate_value_type(%MeasurementStream{}, %Point{}), do: {:error, :value_type_mismatch}

  defp resolve_property_id!(opts) do
    slug = Keyword.get(opts, :property_slug, @default_property_slug)

    case Topology.get_property_by_slug(slug) do
      {:ok, %{id: id}} -> id
      {:error, :property_not_found} -> raise "property not found: #{slug}"
    end
  end
end
