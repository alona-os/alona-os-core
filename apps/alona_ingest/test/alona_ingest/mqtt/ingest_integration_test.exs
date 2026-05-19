defmodule AlonaIngest.Mqtt.IngestMQTTIntegrationTest do
  use AlonaCore.DataCase, async: true

  import AlonaIngest.Fixtures

  alias AlonaCore.Measurements.{CurrentValue, MeasurementStream}
  alias AlonaCore.Repo
  alias AlonaIngest.Mqtt.TopicRouter

  @mqtt_topic "alona/esp32/living-room/telemetry"

  @payload Jason.encode!(%{
            "version" => 1,
            "device_id" => "living-room-node-01",
            "measured_at" => "2026-05-19T19:30:00Z",
            "readings" => %{
              "temperature_c" => 22.5,
              "relative_humidity_pct" => 59.2
            }
          })

  test "mqtt-shaped json persists both env_living envelopes through route/2" do
    telemetry_fixture(slug: "env_living_temp_c")
    telemetry_fixture(slug: "env_living_rh")

    assert TopicRouter.route(@mqtt_topic, @payload) == {:ok, :ingested}

    temp_stream = Repo.get_by!(MeasurementStream, slug: "env_living_temp_c")
    rh_stream = Repo.get_by!(MeasurementStream, slug: "env_living_rh")

    temp_cv = Repo.get!(CurrentValue, temp_stream.id)
    rh_cv = Repo.get!(CurrentValue, rh_stream.id)

    assert_in_delta(temp_cv.latest_value, 22.5, 1.0e-6)
    assert_in_delta(rh_cv.latest_value, 59.2, 1.0e-6)
  end
end
