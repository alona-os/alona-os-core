defmodule AlonaUiWeb.DashboardPresenter do
  @moduledoc """
  aggregates `alona_core` reads into view-friendly binds for dashboards.
  """
  alias AlonaCore.Events
  alias AlonaCore.Measurements
  alias AlonaCore.Tasks

  @command_slugs ~w(
    energy_battery_soc
    energy_pv_kw
    energy_house_load_kw
    energy_battery_flow_kw
    energy_generator_status
    water_tank_percent
    water_tank_liters
    water_daily_liters_estimate
    water_well_status
    water_pump_status
    env_living_temp_c
    env_living_rh
    env_bedroom_temp_c
    env_bedroom_rh
    env_bathroom_temp_c
    env_bathroom_rh
  )

  def command_center_binds do
    streams = Measurements.streams_for_slugs(@command_slugs)

    %{
      streams: streams,
      stream_map: slug_map(streams),
      alerts: Events.list_alert_events(5),
      today_tasks: today_and_overdue_tasks(),
      timeline: Events.list_recent_events(10)
    }
  end

  defp slug_map(streams) do
    streams
    |> Enum.filter(& &1.current_value)
    |> Map.new(fn s -> {s.slug, s.current_value} end)
  end

  defp today_and_overdue_tasks do
    today = Date.utc_today()

    Tasks.list_tasks()
    |> Enum.filter(fn task ->
      cond do
        task.status == "overdue" -> true
        task.status == "completed" -> false
        task.due_at == nil -> false
        true -> DateTime.to_date(task.due_at) == today
      end
    end)
  end

  def slug_number(stream_map, slug) when is_binary(slug) do
    case Map.get(stream_map, slug) do
      %{latest_value: n} -> n
      _ -> nil
    end
  end

  def slug_text(stream_map, slug) when is_binary(slug) do
    case Map.get(stream_map, slug) do
      %{latest_value_text: t} -> t || ""
      _ -> ""
    end
  end

  def slug_timestamp(stream_map, slug) when is_binary(slug) do
    case Map.get(stream_map, slug) do
      %{measured_at: at} -> at
      _ -> nil
    end
  end

  def room_cards(stream_map) do
    [
      %{title: "Living Room", temp_key: "env_living_temp_c", rh_key: "env_living_rh"},
      %{title: "Bedroom", temp_key: "env_bedroom_temp_c", rh_key: "env_bedroom_rh"},
      %{title: "Bathroom", temp_key: "env_bathroom_temp_c", rh_key: "env_bathroom_rh"}
    ]
    |> Enum.map(fn room ->
      measured_at =
        slug_timestamp(stream_map, room.temp_key) || slug_timestamp(stream_map, room.rh_key)

      %{
        name: room.title,
        temperature: slug_number(stream_map, room.temp_key),
        humidity: slug_number(stream_map, room.rh_key),
        last_seen: measured_at,
        sensor_status: recent_enough?(measured_at)
      }
    end)
  end

  defp recent_enough?(nil), do: :offline

  defp recent_enough?(%DateTime{} = at) do
    diff = DateTime.diff(DateTime.utc_now(:microsecond), at, :minute)

    if diff <= 20 do
      :online
    else
      :offline
    end
  end

  defp recent_enough?(_), do: :offline
end
