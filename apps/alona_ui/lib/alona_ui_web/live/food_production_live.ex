defmodule AlonaUiWeb.FoodProductionLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Food Production")
     |> assign(:active_nav, :food)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Food production lane</p>

      <p class="mt-2 text-sm text-base-content/65">
        propagation + harvest tracking ships after resource flows stabilize.
      </p>
    </article>
    """
  end
end
