defmodule AlonaIngest.Adapters.Esp32AdapterTest do
  use ExUnit.Case, async: true

  alias AlonaCore.Telemetry.Point
  alias AlonaIngest.Adapters.Esp32Adapter
  alias AlonaIngest.Telemetry.Envelope

  @payload %{
    "version" => 1,
    "device_id" => "living-room-node-01",
    "measured_at" => "2026-05-19T19:30:00Z",
    "readings" => %{
      "temperature_c" => 22.4,
      "relative_humidity_pct" => 58.1
    },
    "battery_mv" => 4120,
    "rssi_dbm" => -67
  }

  describe "normalize/1" do
    test "happy path returns two envelopes for temperature and humidity" do
      assert {:ok, envelopes} = Esp32Adapter.normalize(@payload)
      assert length(envelopes) == 2

      [rh, temp] = envelopes

      assert rh == %{
               "stream_slug" => "env_living_rh",
               "value" => 58.1,
               "measured_at" => "2026-05-19T19:30:00Z",
               "raw" => %{
                 "adapter" => "esp32",
                 "device_id" => "living-room-node-01",
                 "reading" => "relative_humidity_pct",
                 "payload_version" => 1,
                 "battery_mv" => 4120,
                 "rssi_dbm" => -67
               }
             }

      assert temp == %{
               "stream_slug" => "env_living_temp_c",
               "value" => 22.4,
               "measured_at" => "2026-05-19T19:30:00Z",
               "raw" => %{
                 "adapter" => "esp32",
                 "device_id" => "living-room-node-01",
                 "reading" => "temperature_c",
                 "payload_version" => 1,
                 "battery_mv" => 4120,
                 "rssi_dbm" => -67
               }
             }
    end

    test "accepts JSON binary input" do
      json = Jason.encode!(@payload)

      assert {:ok, envelopes} = Esp32Adapter.normalize(json)
      assert length(envelopes) == 2
    end

    test "single temperature reading returns one envelope" do
      payload =
        Map.put(@payload, "readings", %{"temperature_c" => 21.0})

      assert {:ok, [envelope]} = Esp32Adapter.normalize(payload)
      assert envelope["stream_slug"] == "env_living_temp_c"
      assert envelope["value"] == 21.0
    end

    test "unknown readings only returns no_mappable_readings" do
      payload = Map.put(@payload, "readings", %{"pressure_hpa" => 1013.0})

      assert {:error, :no_mappable_readings} = Esp32Adapter.normalize(payload)
    end

    test "mixed known and unknown readings returns only known envelope" do
      payload =
        Map.put(@payload, "readings", %{
          "temperature_c" => 20.0,
          "pressure_hpa" => 1013.0
        })

      assert {:ok, [envelope]} = Esp32Adapter.normalize(payload)
      assert envelope["stream_slug"] == "env_living_temp_c"
    end

    test "unsupported version returns unsupported_version" do
      payload = Map.put(@payload, "version", 2)

      assert {:error, :unsupported_version} = Esp32Adapter.normalize(payload)
    end

    test "missing device_id returns invalid_payload" do
      payload = Map.delete(@payload, "device_id")

      assert {:error, :invalid_payload} = Esp32Adapter.normalize(payload)
    end

    test "missing readings returns invalid_payload" do
      payload = Map.delete(@payload, "readings")

      assert {:error, :invalid_payload} = Esp32Adapter.normalize(payload)
    end

    test "invalid JSON returns invalid_json" do
      assert {:error, :invalid_json} = Esp32Adapter.normalize("{not json")
    end

    test "non-map input returns invalid_payload" do
      assert {:error, :invalid_payload} = Esp32Adapter.normalize(123)
    end

    test "omits measured_at when input does not provide it" do
      payload = Map.delete(@payload, "measured_at")

      assert {:ok, [envelope | _]} = Esp32Adapter.normalize(payload)
      refute Map.has_key?(envelope, "measured_at")
    end

    test "omits optional raw fields when absent" do
      payload =
        @payload
        |> Map.delete("battery_mv")
        |> Map.delete("rssi_dbm")

      assert {:ok, [envelope | _]} = Esp32Adapter.normalize(payload)
      raw = envelope["raw"]

      refute Map.has_key?(raw, "battery_mv")
      refute Map.has_key?(raw, "rssi_dbm")
    end

    test "skips non-numeric known readings" do
      payload =
        Map.put(@payload, "readings", %{
          "temperature_c" => "warm",
          "relative_humidity_pct" => 50.0
        })

      assert {:ok, [envelope]} = Esp32Adapter.normalize(payload)
      assert envelope["stream_slug"] == "env_living_rh"
    end

    test "accepts atom keys in prebuilt maps" do
      payload = %{
        version: 1,
        device_id: "living-room-node-01",
        readings: %{temperature_c: 19.0}
      }

      assert {:ok, [envelope]} = Esp32Adapter.normalize(payload)
      assert envelope["stream_slug"] == "env_living_temp_c"
      assert envelope["value"] == 19.0
    end

    test "envelopes parse to valid Point structs" do
      assert {:ok, envelopes} = Esp32Adapter.normalize(@payload)

      for envelope <- envelopes do
        assert {:ok, %Point{stream_slug: slug, value_number: value}} = Envelope.parse(envelope)
        assert is_binary(slug)
        assert is_number(value)
      end
    end
  end
end
