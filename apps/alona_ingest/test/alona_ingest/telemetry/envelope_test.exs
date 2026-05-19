defmodule AlonaIngest.Telemetry.EnvelopeTest do
  use ExUnit.Case, async: true

  alias AlonaCore.Telemetry.Point
  alias AlonaIngest.Telemetry.Envelope

  describe "parse/1" do
    test "maps a valid envelope to a Point" do
      {:ok, measured_at, _} = DateTime.from_iso8601("2026-05-19T18:00:00Z")

      assert {:ok, %Point{} = point} =
               Envelope.parse(%{
                 "stream_slug" => "env_living_temp_c",
                 "value" => 23.4,
                 "measured_at" => "2026-05-19T18:00:00Z",
                 "quality" => 80,
                 "property_slug" => "default-site",
                 "raw" => %{"source" => "test"}
               })

      assert point.stream_slug == "env_living_temp_c"
      assert point.value_number == 23.4
      assert point.measured_at == measured_at
      assert point.quality == 80
      assert point.property_slug == "default-site"
      assert point.raw_payload == %{"source" => "test"}
    end

    test "defaults quality to 100 when omitted" do
      assert {:ok, %Point{quality: 100}} =
               Envelope.parse(%{"stream_slug" => "env_living_temp_c", "value" => 1.0})
    end

    test "defaults measured_at in parser when omitted" do
      before = DateTime.utc_now(:microsecond)

      assert {:ok, %Point{measured_at: measured_at}} =
               Envelope.parse(%{"stream_slug" => "env_living_temp_c", "value" => 1.0})

      after_ = DateTime.utc_now(:microsecond)
      assert DateTime.compare(measured_at, before) in [:eq, :gt]
      assert DateTime.compare(measured_at, after_) in [:eq, :lt]
    end

    test "rejects missing stream_slug" do
      assert {:error, :invalid_envelope} =
               Envelope.parse(%{"value" => 1.0})
    end

    test "rejects non-number value" do
      assert {:error, :invalid_envelope} =
               Envelope.parse(%{"stream_slug" => "x", "value" => "hot"})
    end

    test "rejects invalid measured_at" do
      assert {:error, :invalid_measured_at} =
               Envelope.parse(%{
                 "stream_slug" => "x",
                 "value" => 1.0,
                 "measured_at" => "not-a-datetime"
               })
    end

    test "rejects string quality" do
      assert {:error, :invalid_quality} =
               Envelope.parse(%{
                 "stream_slug" => "x",
                 "value" => 1.0,
                 "quality" => "good"
               })
    end

    test "rejects quality outside 0..100" do
      assert {:error, :invalid_quality} =
               Envelope.parse(%{
                 "stream_slug" => "x",
                 "value" => 1.0,
                 "quality" => 101
               })
    end

    test "rejects non-map envelope" do
      assert {:error, :invalid_envelope} = Envelope.parse("not a map")
    end
  end

  describe "decode/1" do
    test "decodes valid JSON" do
      json = ~s({"stream_slug":"env_living_temp_c","value":23.4})

      assert {:ok, %{"stream_slug" => "env_living_temp_c", "value" => 23.4}} =
               Envelope.decode(json)
    end

    test "rejects invalid JSON" do
      assert {:error, :invalid_json} = Envelope.decode("{")
    end
  end
end
