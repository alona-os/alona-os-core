defmodule AlonaUiWeb.MaintenanceLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Maintenance")
     |> assign(:active_nav, :maintenance)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Maintenance planner</p>

      <p class="mt-2 text-sm text-base-content/65">
        equipment schedules + spares — hook into tasks & protocol library next.
      </p>
    </article>
    """
  end
end
