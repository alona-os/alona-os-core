defmodule AlonaIngest.Mqtt.TopicRouterTest do
  use AlonaCore.DataCase, async: true

  import AlonaIngest.Fixtures

  alias AlonaCore.Measurements.MeasurementStream
  alias AlonaCore.Repo
  alias AlonaIngest.Mqtt.TopicRouter

  @mqtt_topic "alona/esp32/living-room/telemetry"

  @payload Jason.encode!(%{
            "version" => 1,
            "device_id" => "living-room-node-01",
            "measured_at" => "2026-05-19T19:30:00Z",
            "readings" => %{
              "temperature_c" => 22.4,
              "relative_humidity_pct" => 58.1
            }
          })

  defp encode_payload(attrs), do: Jason.encode!(attrs)

  describe "route/2" do
    test "unknown topic returns :ignored" do
      assert TopicRouter.route("some/other/topic", @payload) == {:ok, :ignored}
    end

    test "invalid json returns normalize error from adapter path" do
      assert TopicRouter.route(@mqtt_topic, "{not json") == {:error, :invalid_json}
    end

    test "empty mqtt payload returns invalid_json" do
      assert TopicRouter.route(@mqtt_topic, <<>>) == {:error, :invalid_json}
    end

    test "unsupported version returns unsupported_version" do
      payload =
        encode_payload(%{
          "version" => 2,
          "device_id" => "living-room-node-01",
          "readings" => %{"temperature_c" => 20.0}
        })

      assert TopicRouter.route(@mqtt_topic, payload) == {:error, :unsupported_version}
    end

    test "missing device_id returns invalid_payload" do
      payload =
        encode_payload(%{
          "version" => 1,
          "readings" => %{"temperature_c" => 20.0}
        })

      assert TopicRouter.route(@mqtt_topic, payload) == {:error, :invalid_payload}
    end

    test "no mappable readings returns no_mappable_readings" do
      payload =
        encode_payload(%{
          "version" => 1,
          "device_id" => "living-room-node-01",
          "readings" => %{}
        })

      assert TopicRouter.route(@mqtt_topic, payload) == {:error, :no_mappable_readings}
    end

    test "ingests both readings when streams exist" do
      telemetry_fixture(slug: "env_living_temp_c")
      telemetry_fixture(slug: "env_living_rh")

      assert TopicRouter.route(@mqtt_topic, @payload) == {:ok, :ingested}
    end

    test "returns partial_ingest_failed when rh stream missing" do
      telemetry_fixture(slug: "env_living_temp_c")

      assert {:error, {:partial_ingest_failed, failures}} =
               TopicRouter.route(@mqtt_topic, @payload)

      assert {"env_living_rh", :stream_not_found} in failures
      refute {"env_living_temp_c", :stream_not_found} in failures

      temp_stream = Repo.get_by!(MeasurementStream, slug: "env_living_temp_c")
      temp_cv = Repo.get!(AlonaCore.Measurements.CurrentValue, temp_stream.id)

      assert_in_delta(temp_cv.latest_value, 22.4, 1.0e-6)

      refute Repo.get_by(MeasurementStream, slug: "env_living_rh")
    end
  end
end
