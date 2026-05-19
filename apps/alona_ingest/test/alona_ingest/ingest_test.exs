defmodule AlonaIngest.IngestTest do
  use AlonaCore.DataCase, async: true

  import AlonaIngest.Fixtures

  alias AlonaCore.Measurements.{CurrentValue, Measurement}
  alias AlonaCore.Repo
  alias AlonaIngest.Ingest

  describe "ingest/1" do
    test "persists measurement and current_value from envelope map" do
      %{property: property, stream: stream} = telemetry_fixture()

      measured_at = ~U[2026-05-19 18:00:00.000000Z]

      assert {:ok, %{measurement: measurement, current_value: current}} =
               Ingest.ingest(%{
                 "stream_slug" => stream.slug,
                 "value" => 23.4,
                 "measured_at" => "2026-05-19T18:00:00Z",
                 "quality" => 90,
                 "property_slug" => property.slug,
                 "raw" => %{"source" => "test"}
               })

      assert measurement.stream_id == stream.id
      assert measurement.value_number == 23.4
      assert measurement.measured_at == measured_at
      assert measurement.quality == 90
      assert measurement.raw_payload == %{"source" => "test"}

      assert current.stream_id == stream.id
      assert current.latest_value == 23.4
      assert current.measured_at == measured_at

      assert Repo.aggregate(from(m in Measurement, where: m.stream_id == ^stream.id), :count) >= 1
      assert %CurrentValue{} = Repo.get!(CurrentValue, stream.id)
    end

    test "persists from JSON binary" do
      %{property: property, stream: stream} = telemetry_fixture()

      json =
        Jason.encode!(%{
          "stream_slug" => stream.slug,
          "value" => 19.5,
          "property_slug" => property.slug
        })

      assert {:ok, %{measurement: measurement}} = Ingest.ingest(json)
      assert measurement.value_number == 19.5
    end

    test "returns stream_not_found for unknown slug" do
      %{property: property} = telemetry_fixture()

      assert {:error, :stream_not_found} =
               Ingest.ingest(%{
                 "stream_slug" => "missing_stream",
                 "value" => 1.0,
                 "property_slug" => property.slug
               })
    end

    test "does not persist on parse failure" do
      %{stream: stream} = telemetry_fixture()

      count_before =
        Repo.aggregate(from(m in Measurement, where: m.stream_id == ^stream.id), :count)

      assert {:error, :invalid_envelope} =
               Ingest.ingest(%{"stream_slug" => stream.slug})

      count_after =
        Repo.aggregate(from(m in Measurement, where: m.stream_id == ^stream.id), :count)

      assert count_after == count_before
    end
  end
end
