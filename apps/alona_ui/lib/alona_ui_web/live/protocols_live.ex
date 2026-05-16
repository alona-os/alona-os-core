defmodule AlonaUiWeb.ProtocolsLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Protocols")
     |> assign(:active_nav, :protocols)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Runbooks</p>

      <p class="mt-2 text-sm text-base-content/65">
        emergency + seasonal procedures — modeled after Notion playbook export later.
      </p>
    </article>
    """
  end
end
