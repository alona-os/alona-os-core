defmodule AlonaUiWeb.EnergyLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.Measurements

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

    assign(socket,
      battery: value_for(map, "energy_battery_soc"),
      pv: value_for(map, "energy_pv_kw"),
      load: value_for(map, "energy_house_load_kw"),
      flow: value_for(map, "energy_battery_flow_kw"),
      generator: text_for(map, "energy_generator_status")
    )
  end

  defp value_for(map, slug) do
    case Map.get(map, slug) do
      nil -> nil
      %{latest_value: num} -> num
    end
  end

  defp text_for(map, slug) do
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
      <p class="text-xs uppercase tracking-[0.3em] text-base-content/55">energy branch</p>

      <h1 class="text-3xl font-semibold">Power & storage</h1>

      <p class="text-sm text-base-content/65">first vertical slice wiring for victron-style KPIs.</p>
    </section>

    <section class="mt-8 grid gap-4 md:grid-cols-4">
      <.metric_card title="Battery SOC" value={@battery} unit="%" status={soc_status(@battery)} />
      <.metric_card title="PV production" value={@pv} unit="kW" subtitle="array output" status="success" />
      <.metric_card title="House load" value={@load} unit="kW" subtitle="aggregate" />
      <.metric_card title="Battery flow" value={@flow} unit="kW" subtitle="+ charge / - discharge" />
    </section>

    <section class="mt-10 grid gap-4 lg:grid-cols-2">
      <article class="rounded-xl border bg-base-100 p-5 shadow-sm border-base-200 space-y-3">
        <header>
          <p class="text-sm font-semibold">generator</p>

          <p class="text-xs text-base-content/55">text status stream until automations land</p>
        </header>

        <p class="text-3xl font-semibold"><%= format_status(@generator) %></p>
      </article>

      <article class="rounded-xl border border-dashed border-base-300 p-5 text-sm text-base-content/60">
        SOC history chart hooks into `measurements` table · not rendered in this slice yet.
      </article>
    </section>
    """
  end

  defp soc_status(nil), do: "normal"
  defp soc_status(level) when is_number(level) and level <= 25, do: "error"
  defp soc_status(level) when is_number(level) and level <= 50, do: "warning"
  defp soc_status(_), do: "success"

  defp format_status(""), do: "unknown"
  defp format_status(text), do: text |> String.replace("_", " ") |> String.capitalize()
end
