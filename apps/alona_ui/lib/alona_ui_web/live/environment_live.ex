defmodule AlonaUiWeb.EnvironmentLive do
  use AlonaUiWeb, :live_view

  alias AlonaUiWeb.DashboardPresenter

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Environment")
      |> assign(:active_nav, :environment)

    {:ok, reload(socket)}
  end

  defp reload(socket) do
    binds = DashboardPresenter.command_center_binds()

    rooms = DashboardPresenter.room_cards(binds.stream_map)

    assign(socket, rooms: rooms)
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">environment branch</p>

      <h1 class="text-3xl font-semibold tracking-tight">Indoor comfort</h1>

      <p class="text-sm text-base-content/65">
        seeded room nodes mirror the MVP React cards for living spaces.
      </p>
    </section>

    <div class="mt-8 grid gap-4 lg:grid-cols-3">
      <%= for room <- @rooms do %>
        <.room_card
          name={room.name}
          temperature={room.temperature}
          humidity={room.humidity}
          sensor_status={room.sensor_status}
          last_seen={room.last_seen}
        />
      <% end %>
    </div>

    <div class="mt-10 rounded-xl border border-dashed border-base-300 p-6 text-sm text-base-content/60">
      multi-series temperature comparisons will reuse `measurements` rollup helpers later.
    </div>
    """
  end
end
