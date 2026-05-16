defmodule AlonaUiWeb.TimelineLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.Events

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Timeline")
      |> assign(:active_nav, :timeline)

    {:ok, reload(socket)}
  end

  defp reload(socket), do: assign(socket, events: Events.list_recent_events(50))

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">observability</p>

      <h1 class="text-3xl font-semibold tracking-tight">System timeline</h1>

      <p class="text-sm text-base-content/65">
        merges expenses, telemetry alerts, tasks, etc. sourced from MVP `events` table.
      </p>
    </section>

    <div class="mt-8 divide-y divide-base-200 rounded-xl border border-base-200 bg-base-100 px-2 shadow-sm">
      <%= if @events == [] do %>
        <p class="py-12 text-center text-sm text-base-content/60">no events yet.</p>
      <% else %>
        <%= for evt <- @events do %>
          <.timeline_item event={evt} />
        <% end %>
      <% end %>
    </div>
    """
  end
end
