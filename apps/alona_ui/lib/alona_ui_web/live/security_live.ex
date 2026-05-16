defmodule AlonaUiWeb.SecurityLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Security")
     |> assign(:active_nav, :security)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Security posture</p>

      <p class="mt-2 text-sm text-base-content/65">
        cameras, access, audit trail — placeholder until security events ingest exists.
      </p>
    </article>
    """
  end
end
