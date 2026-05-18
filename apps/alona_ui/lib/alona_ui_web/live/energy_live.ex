defmodule AlonaUiWeb.EnergyLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.{Events, Measurements}
  alias AlonaUiWeb.DashboardPresenter

  @slugs ~w(energy_battery_soc energy_pv_kw energy_house_load_kw energy_battery_flow_kw energy_generator_status)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Energy")
      |> assign(:active_nav, :energy)

    {:ok, reload(socket)}
  end

  defp reload(socket) do
    streams = Measurements.streams_for_slugs(@slugs)

    map =
      streams
      |> Enum.filter(&(&1.current_value != nil))
      |> Map.new(fn s -> {s.slug, s.current_value} end)

    events =
      Events.list_recent_events(20)
      |> Enum.filter(&energy_event?/1)
      |> Enum.take(5)

    assign(socket,
      battery: DashboardPresenter.slug_number(map, "energy_battery_soc"),
      pv: DashboardPresenter.slug_number(map, "energy_pv_kw"),
      load: DashboardPresenter.slug_number(map, "energy_house_load_kw"),
      flow: DashboardPresenter.slug_number(map, "energy_battery_flow_kw"),
      generator: DashboardPresenter.slug_text(map, "energy_generator_status"),
      events: events
    )
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold tracking-tight">Energy</h1>
        <p class="text-sm text-base-content/60">Solar, battery and power management</p>
      </div>

      <section>
        <h2 class="mb-3 text-sm font-medium text-base-content/60">Current Status</h2>

        <div class="grid grid-cols-2 gap-4 md:grid-cols-5">
          <.metric_card
            title="Battery SOC"
            value={@battery}
            unit="%"
            icon="hero-battery-100"
            status={soc_status(@battery)}
          />
          <.metric_card
            title="PV Power"
            value={pretty_kw(@pv)}
            unit="kW"
            icon="hero-sun"
            subtitle={pv_subtitle(@pv)}
            status="success"
          />
          <.metric_card
            title="House Load"
            value={pretty_kw(@load)}
            unit="kW"
            icon="hero-home"
          />
          <.metric_card
            title="Battery"
            value={flow_value(@flow)}
            unit="kW"
            icon="hero-bolt"
            subtitle={flow_subtitle(@flow)}
            status={flow_status(@flow)}
          />
          <.metric_card
            title="Generator"
            value={format_status(@generator)}
            icon="hero-power"
            subtitle="Backup ready"
            status={generator_status(@generator)}
          />
        </div>
      </section>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <.chart_placeholder_card
          title="Battery SOC History"
          description="Last 24 hours"
          note="SOC area chart hooks into measurement rollups"
        />
        <.chart_placeholder_card
          title="Power Production vs Load"
          description="Last 24 hours"
          note="PV and house load series from measurements"
        />
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
          <header class="space-y-1 px-5 pb-2 pt-5">
            <p class="text-base font-medium">Recent Energy Events</p>
          </header>

          <div class="divide-y divide-base-200 px-5 pb-5">
            <%= if @events == [] do %>
              <p class="py-4 text-center text-sm text-base-content/60">No recent events</p>
            <% else %>
              <%= for event <- @events do %>
                <div class="flex items-center justify-between gap-4 py-3">
                  <div class="min-w-0">
                    <p class="text-sm font-medium">{event.title}</p>
                    <p :if={event.description} class="text-xs text-base-content/60">
                      {event.description}
                    </p>
                  </div>

                  <span class="shrink-0 text-xs text-base-content/55">
                    {time_ago(event.occurred_at)}
                  </span>
                </div>
              <% end %>
            <% end %>
          </div>
        </article>

        <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
          <header class="space-y-1 px-5 pb-2 pt-5">
            <p class="text-base font-medium">Energy Automations</p>
          </header>

          <div class="px-5 pb-5">
            <p class="py-4 text-center text-sm text-base-content/60">
              Automations workshop ships after rules engine wiring.
            </p>
          </div>
        </article>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :note, :string, required: true

  defp chart_placeholder_card(assigns) do
    ~H"""
    <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
      <header class="space-y-1 px-5 pb-2 pt-5">
        <p class="text-base font-medium">{@title}</p>
        <p class="text-sm text-base-content/60">{@description}</p>
      </header>

      <div class="flex h-64 items-center justify-center px-5 pb-5">
        <p class="text-center text-sm text-base-content/55">{@note}</p>
      </div>
    </article>
    """
  end

  defp energy_event?(event) do
    haystack =
      [event.title, event.description, event.event_type]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.downcase()

    String.contains?(haystack, [
      "battery",
      "soc",
      "generator",
      "pv",
      "solar",
      "power",
      "grid",
      "inverter",
      "charge",
      "discharge"
    ])
  end

  defp soc_status(nil), do: "normal"
  defp soc_status(level) when is_number(level) and level <= 25, do: "error"
  defp soc_status(level) when is_number(level) and level <= 50, do: "warning"
  defp soc_status(_), do: "success"

  defp flow_status(nil), do: "normal"
  defp flow_status(flow) when is_number(flow) and flow > 0, do: "success"
  defp flow_status(flow) when is_number(flow) and flow < 0, do: "warning"
  defp flow_status(_), do: "normal"

  defp generator_status("running"), do: "warning"
  defp generator_status(_), do: "normal"

  defp flow_value(nil), do: "-"

  defp flow_value(flow) when is_number(flow) and flow > 0 do
    "+#{pretty_kw(flow)}"
  end

  defp flow_value(flow) when is_number(flow), do: pretty_kw(flow)
  defp flow_value(_), do: "-"

  defp flow_subtitle(nil), do: nil
  defp flow_subtitle(flow) when is_number(flow) and flow > 0, do: "Charging"
  defp flow_subtitle(flow) when is_number(flow) and flow < 0, do: "Discharging"
  defp flow_subtitle(_), do: nil

  defp pv_subtitle(nil), do: nil
  defp pv_subtitle(pv) when is_number(pv) and pv > 0, do: "Active"
  defp pv_subtitle(_), do: nil

  defp pretty_kw(nil), do: "-"
  defp pretty_kw(value) when is_number(value), do: Float.round(value * 1.0, 1)
  defp pretty_kw(_), do: "-"

  defp format_status(""), do: "unknown"
  defp format_status(text), do: text |> String.replace("_", " ") |> String.capitalize()

  defp time_ago(%DateTime{} = at) do
    minutes = DateTime.diff(DateTime.utc_now(:microsecond), at, :minute) |> max(0)

    cond do
      minutes < 60 -> "#{minutes}m ago"
      minutes < 1440 -> "#{div(minutes, 60)}h ago"
      true -> "#{div(minutes, 1440)}d ago"
    end
  end

  defp time_ago(_), do: ""
end
