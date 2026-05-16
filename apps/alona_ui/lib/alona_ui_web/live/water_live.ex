defmodule AlonaUiWeb.WaterLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.Measurements

  @slugs ~w(water_tank_percent water_tank_liters water_daily_liters_estimate water_well_status water_pump_status)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Water")
      |> assign(:active_nav, :water)

    {:ok, reload(socket)}
  end

  defp reload(socket) do
    streams = Measurements.streams_for_slugs(@slugs)

    map =
      streams
      |> Enum.filter(&(&1.current_value != nil))
      |> Map.new(fn s -> {s.slug, s.current_value} end)

    assign(socket,
      tank_pct: number(map, "water_tank_percent"),
      liters: number(map, "water_tank_liters"),
      usage: number(map, "water_daily_liters_estimate"),
      well: text(map, "water_well_status"),
      pump: text(map, "water_pump_status")
    )
  end

  defp number(map, slug) do
    case Map.get(map, slug) do
      nil -> nil
      %{latest_value: num} -> num
    end
  end

  defp text(map, slug) do
    case Map.get(map, slug) do
      nil -> ""
      %{latest_value_text: t} -> t || ""
    end
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">water branch</p>

      <h1 class="text-3xl font-semibold tracking-tight">Tanks & pumping</h1>

      <p class="text-sm text-base-content/65">
        live values follow the `water_*` measurement slugs until MQTT ingest ships.
      </p>
    </section>

    <section class="mt-8 grid gap-4 md:grid-cols-3">
      <.metric_card title="Tank level" value={@tank_pct} unit="%" status={tank_tone(@tank_pct)} />
      <.metric_card title="Estimated liters" value={@liters} unit="L" />
      <.metric_card title="Daily usage est." value={@usage} unit="L" />
    </section>

    <section class="mt-10 grid gap-4 md:grid-cols-2">
      <article class="rounded-xl border bg-base-100 p-5 shadow-sm border-base-200">
        <p class="text-sm font-semibold">well</p>

        <p class="mt-3 text-2xl font-semibold"><%= labelize(@well) %></p>
      </article>

      <article class="rounded-xl border bg-base-100 p-5 shadow-sm border-base-200">
        <p class="text-sm font-semibold">pump</p>

        <p class="mt-3 text-2xl font-semibold"><%= labelize(@pump) %></p>
      </article>
    </section>

    <div class="mt-10 rounded-xl border border-dashed border-base-300 p-6 text-sm text-base-content/60">
      weekly usage chart deferred · data already lands in measurements/current_values.
    </div>
    """
  end

  defp tank_tone(nil), do: "warning"
  defp tank_tone(level) when is_number(level) and level <= 40, do: "warning"
  defp tank_tone(_), do: "normal"

  defp labelize(""), do: "unknown"
  defp labelize(text), do: text |> String.replace("_", " ") |> String.capitalize()
end
