defmodule AlonaCore.MeasurementsIngestTest do
  use AlonaCore.DataCase, async: true

  alias AlonaCore.Measurements
  alias AlonaCore.Measurements.{CurrentValue, MeasurementStream, MetricDefinition}
  alias AlonaCore.Repo
  alias AlonaCore.Telemetry.Point
  alias AlonaCore.Topology.Property

  describe "ingest_point/1" do
    test "inserts measurement and updates current_values" do
      %{property: property, stream: stream} = telemetry_fixture()

      measured_at = DateTime.utc_now(:microsecond)

      assert {:ok, %{measurement: measurement, current_value: current}} =
               Measurements.ingest_point(%Point{
                 property_slug: property.slug,
                 stream_slug: stream.slug,
                 value_number: 22.4,
                 measured_at: measured_at,
                 quality: 100,
                 raw_payload: %{"test" => true}
               })

      assert measurement.stream_id == stream.id
      assert measurement.value_number == 22.4
      assert measurement.measured_at == measured_at
      assert measurement.raw_payload == %{"test" => true}

      assert current.stream_id == stream.id
      assert current.latest_value == 22.4
      assert current.measured_at == measured_at
    end

    test "persists provided measured_at" do
      %{property: property, stream: stream} = telemetry_fixture()
      measured_at = ~U[2020-01-01 12:00:00.000000Z]

      assert {:ok, %{measurement: measurement}} =
               Measurements.ingest_point(%Point{
                 property_slug: property.slug,
                 stream_slug: stream.slug,
                 value_number: 19.0,
                 measured_at: measured_at
               })

      assert measurement.measured_at == measured_at
    end

    test "returns stream_not_found for unknown slug" do
      %{property: property} = telemetry_fixture()

      assert {:error, :stream_not_found} =
               Measurements.ingest_point(%Point{
                 property_slug: property.slug,
                 stream_slug: "missing_stream",
                 value_number: 1.0
               })
    end

    test "returns value_type_mismatch for wrong value field" do
      %{property: property, stream: stream} = telemetry_fixture()

      assert {:error, :value_type_mismatch} =
               Measurements.ingest_point(%Point{
                 property_slug: property.slug,
                 stream_slug: stream.slug,
                 value_text: "not-a-number"
               })
    end

    test "isolates streams by property" do
      property_a = insert_property!("site-a")
      property_b = insert_property!("site-b")

      stream_a = insert_stream!(property_a, "env_living_temp_c")
      stream_b = insert_stream!(property_b, "env_living_temp_c")

      assert {:ok, %{current_value: current_a}} =
               Measurements.ingest_point(%Point{
                 property_slug: property_a.slug,
                 stream_slug: stream_a.slug,
                 value_number: 11.1
               })

      assert current_a.latest_value == 11.1
      refute Repo.get(CurrentValue, stream_b.id)
    end
  end

  describe "ingest_points/1" do
    test "returns ok when all points succeed" do
      %{property: property, stream: stream} = telemetry_fixture()

      points = [
        %Point{property_slug: property.slug, stream_slug: stream.slug, value_number: 1.0},
        %Point{property_slug: property.slug, stream_slug: stream.slug, value_number: 2.0}
      ]

      assert {:ok, results} = Measurements.ingest_points(points)
      assert length(results) == 2
      assert Enum.all?(results, &match?({:ok, _}, &1))
    end

    test "returns partial when mixed success and failure" do
      %{property: property, stream: stream} = telemetry_fixture()

      points = [
        %Point{property_slug: property.slug, stream_slug: stream.slug, value_number: 1.0},
        %Point{property_slug: property.slug, stream_slug: "missing", value_number: 2.0}
      ]

      assert {:partial, results} = Measurements.ingest_points(points)
      assert match?({:ok, _}, Enum.at(results, 0))
      assert match?({:error, :stream_not_found}, Enum.at(results, 1))
    end

    test "returns error when all points fail" do
      %{property: property} = telemetry_fixture()

      points = [
        %Point{property_slug: property.slug, stream_slug: "missing-a", value_number: 1.0},
        %Point{property_slug: property.slug, stream_slug: "missing-b", value_number: 2.0}
      ]

      assert {:error, results} = Measurements.ingest_points(points)
      assert Enum.all?(results, &match?({:error, :stream_not_found}, &1))
    end
  end

  defp telemetry_fixture do
    property = insert_property!("default-site")
    metric = insert_metric!()
    stream = insert_stream!(property, "env_living_temp_c", metric)
    %{property: property, stream: stream, metric: metric}
  end

  defp insert_property!(slug) do
    case Repo.get_by(Property, slug: slug) do
      %Property{} = property ->
        property

      nil ->
        %Property{}
        |> Property.changeset(%{name: String.capitalize(slug), slug: slug, status: "active"})
        |> Repo.insert!()
    end
  end

  defp insert_metric! do
    %MetricDefinition{}
    |> MetricDefinition.changeset(%{
      name: "temperature_c_#{System.unique_integer()}",
      unit: "°C",
      value_type: "number",
      category: "test"
    })
    |> Repo.insert!()
  end

  defp insert_stream!(property, slug, metric \\ nil) do
    metric = metric || insert_metric!()

    %MeasurementStream{}
    |> MeasurementStream.changeset(%{
      property_id: property.id,
      name: slug,
      slug: slug,
      metric_id: metric.id,
      unit: "°C",
      is_active: true
    })
    |> Repo.insert!()
  end
end
