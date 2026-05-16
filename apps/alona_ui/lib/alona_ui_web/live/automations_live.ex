defmodule AlonaUiWeb.AutomationsLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Automations")
     |> assign(:active_nav, :automations)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center shadow-sm">
      <p class="text-sm font-semibold">Automations workshop</p>

      <p class="mt-2 text-sm text-base-content/65">
        rules engine + actuator hooks land after ingest + state machine hardening.
      </p>
    </article>
    """
  end
end
