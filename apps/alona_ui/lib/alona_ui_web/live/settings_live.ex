defmodule AlonaUiWeb.SettingsLive do
  use AlonaUiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:active_nav, :settings)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">platform shell</p>

      <h1 class="text-3xl font-semibold tracking-tight">Settings</h1>

      <p class="text-sm text-base-content/65">
        placeholders for ingest credentials, alerting thresholds, locales.
      </p>
    </section>

    <div class="mt-8 grid gap-4 md:grid-cols-2">
      <%= for chunk <- placeholders() do %>
        <article class="rounded-xl border border-dashed border-base-300 bg-base-100 p-5 shadow-sm space-y-2">
          <p class="text-sm font-semibold">{chunk.title}</p>

          <p class="text-sm text-base-content/60">{chunk.body}</p>
        </article>
      <% end %>
    </div>
    """
  end

  defp placeholders do
    [
      %{title: "mqtt & gateways", body: "broker url, qos, tls fingerprints — ingest app owns secrets."},
      %{title: "alert routing", body: "pubsub hooks into push/email adapters later."},
      %{title: "users & tenancy", body: "current shell is anonymous; guardian wiring deferred."},
      %{title: "theme & locales", body: "daisy presets + gettext catalogs once copy stabilizes."}
    ]
  end
end
