defmodule AlonaUiWeb.ResourcesLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Resources")
     |> assign(:active_nav, :resources)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Resources hub</p>

      <p class="mt-2 text-sm text-base-content/65">
        stores, inventories, allocations — scaffolding only for this MVP cut.
      </p>
    </article>
    """
  end
end
