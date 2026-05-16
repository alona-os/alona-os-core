defmodule AlonaUiWeb.CommandCenterLive do
  use AlonaUiWeb, :live_view

  alias AlonaUiWeb.DashboardPresenter

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    {:ok,
     socket
     |> assign(:page_title, "command center")
     |> assign(:active_nav, :command_center)
     |> reload_assigns()}
  end

  defp reload_assigns(socket) do
    binds = DashboardPresenter.command_center_binds()
    overdue = Enum.filter(binds.today_tasks, &(&1.status == "overdue"))

    attention =
      Enum.map(binds.alerts, fn evt ->
        %{kind: :alert, title: evt.title, subtitle: evt.description, severity: evt.severity}
      end)
      |> Enum.concat(Enum.map(Enum.take(overdue, 3), fn task -> %{kind: :task, task: task} end))
      |> Enum.take(6)

    stream_map = binds.stream_map

    assign(socket,
      stream_map: stream_map,
      rooms: DashboardPresenter.room_cards(stream_map),
      alerts: binds.alerts,
      today_tasks: Enum.take(binds.today_tasks, 5),
      attention: attention,
      timeline: binds.timeline,
      battery_soc: DashboardPresenter.slug_number(stream_map, "energy_battery_soc"),
      pv_kw: DashboardPresenter.slug_number(stream_map, "energy_pv_kw"),
      load_kw: DashboardPresenter.slug_number(stream_map, "energy_house_load_kw"),
      tank_pct: DashboardPresenter.slug_number(stream_map, "water_tank_percent"),
      liters: DashboardPresenter.slug_number(stream_map, "water_tank_liters"),
      gen_status: DashboardPresenter.slug_text(stream_map, "energy_generator_status")
    )
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload_assigns(socket)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mb-8 space-y-2">
      <p class="text-xs font-semibold uppercase tracking-[0.35em] text-base-content/50">command center</p>

      <h1 class="text-3xl font-semibold tracking-tight">Operational snapshot</h1>

      <p class="text-sm text-base-content/65">energy, indoor comfort and household signals at a glance.</p>
    </section>

    <section class="mb-10 space-y-4">
      <h2 class="text-xs font-semibold uppercase tracking-[0.28em] text-base-content/50">resources snapshot</h2>

      <div class="grid gap-4 md:grid-cols-4">
        <.metric_card
          title="Battery SOC"
          value={@battery_soc}
          unit="%"
          subtitle="battery headroom"
          status={soc_status(@battery_soc)}
        />

        <.metric_card
          title="PV production"
          value={pretty_kw(@pv_kw)}
          unit="kW"
          subtitle="/array instantaneous"
          status="success"
        />

        <.metric_card title="House load" value={pretty_kw(@load_kw)} unit="kW" subtitle="aggregate demand" />

        <.metric_card
          title="Water tank"
          value={@tank_pct}
          unit="%"
          subtitle={"#{liters_hint(@liters)} L est."}
          status={tank_status(@tank_pct)}
        />
      </div>
    </section>

    <section class="space-y-4">
      <h2 class="text-xs font-semibold uppercase tracking-[0.26em] text-base-content/50">indoor environment</h2>

      <div class="grid gap-4 md:grid-cols-3">
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
    </section>

    <%= if @alerts != [] do %>
      <section class="mt-10 space-y-4">
        <h2 class="text-xs font-semibold uppercase tracking-[0.26em] text-base-content/50">active alerts</h2>

        <div class="space-y-3">
          <%= for alert <- @alerts do %>
            <.alert_banner title={alert.title} message={alert.description} severity={alert.severity || "warning"} />
          <% end %>
        </div>
      </section>
    <% end %>

    <section class="mt-10 space-y-3">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <h2 class="text-xs font-semibold uppercase tracking-[0.26em] text-base-content/50">Today's focus</h2>

        <span class="text-xs text-base-content/55"><%= overdue_count(@today_tasks) %> overdue</span>
      </div>

      <div class="space-y-2">
        <%= for task <- @today_tasks do %>
          <.task_item task={task} />
        <% end %>
      </div>
    </section>

    <div class="mt-12 grid gap-10 lg:grid-cols-[minmax(0,7fr)_minmax(260px,3fr)]">
      <section class="space-y-4">
        <h2 class="text-xs font-semibold uppercase tracking-[0.26em] text-base-content/50">system pulses</h2>

        <div class="grid gap-4 sm:grid-cols-4">
          <article class="rounded-xl border bg-base-100 p-4 text-sm shadow-sm border-base-200">
            <p class="text-xs text-base-content/55">automations</p>

            <p class="mt-4 text-xl font-semibold text-base-content/70">planned</p>
          </article>

          <article class="rounded-xl border bg-base-100 p-4 text-sm shadow-sm border-base-200">
            <p class="text-xs text-base-content/55">generator</p>

            <p class="mt-4 text-lg font-semibold"><%= banner_text(@gen_status) %></p>
          </article>

          <article class="rounded-xl border bg-base-100 p-4 text-sm shadow-sm border-base-200">
            <p class="text-xs text-base-content/55">network</p>

            <p class="mt-4 text-xl font-semibold text-success">online</p>
          </article>

          <article class="rounded-xl border bg-base-100 p-4 text-sm shadow-sm border-base-200">
            <p class="text-xs text-base-content/55">security</p>

            <p class="mt-4 text-lg font-semibold text-base-content/60">planned</p>
          </article>
        </div>
      </section>

      <aside class="space-y-6">
        <section class={
          Enum.join(["rounded-xl border bg-base-100 p-5 shadow", attention_border(@attention)], " ")
        }>
          <div class="mb-4 flex items-center justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-[0.3em] text-base-content/55">Needs attention</p>

              <p class="mt-2 text-xl font-semibold"><%= length(@attention) %> signals</p>
            </div>

            <span class={"#{attention_dot(@attention)} h-3 w-3 rounded-full"}></span>
          </div>

          <%= if @attention == [] do %>
            <p class="text-center text-sm text-base-content/60">everything looks steady right now.</p>
          <% else %>
            <div class="space-y-3">
              <%= for entry <- @attention do %>
                <%= if entry.kind == :alert do %>
                  <.alert_banner title={entry.title} message={entry.subtitle} severity={entry.severity || "warning"} compact />
                <% else %>
                  <.task_item task={entry.task} compact />
                <% end %>
              <% end %>
            </div>
          <% end %>
        </section>

        <section class="rounded-xl border bg-base-100 p-5 shadow-sm border-base-200">
          <p class="text-xs uppercase tracking-[0.3em] text-base-content/55">recent timeline</p>

          <div class="mt-4 space-y-0">
            <%= for event <- Enum.take(@timeline, 6) do %>
              <.timeline_item event={event} />
            <% end %>
          </div>
        </section>

        <section class="rounded-xl border bg-base-100 p-5 shadow-sm border-base-200 space-y-3">
          <p class="text-xs uppercase tracking-[0.3em] text-base-content/55">quick actions</p>

          <div class="grid gap-2 sm:grid-cols-2">
            <.link navigate={~p"/tasks"} class="btn btn-outline btn-sm normal-case justify-center">
              jump to tasks
            </.link>

            <.link navigate={~p"/finance"} class="btn btn-outline btn-sm normal-case justify-center">
              log expense
            </.link>

            <.button class="btn btn-outline btn-sm normal-case flex-1" disabled>
              observations (planned)
            </.button>

            <.button class="btn btn-outline btn-sm normal-case flex-1" disabled>
              protocols (planned)
            </.button>
          </div>
        </section>
      </aside>
    </div>
    """
  end

  defp overdue_count(list),
    do: Enum.count(list, fn task -> task.status == "overdue" end)

  defp soc_status(nil), do: "normal"
  defp soc_status(soc) when is_number(soc) and soc <= 25, do: "error"
  defp soc_status(soc) when is_number(soc) and soc <= 50, do: "warning"
  defp soc_status(_), do: "success"

  defp tank_status(nil), do: "warning"
  defp tank_status(level) when is_number(level) and level <= 40, do: "warning"
  defp tank_status(_level), do: "normal"

  defp liters_hint(nil), do: "-"
  defp liters_hint(value) when is_number(value), do: value |> trunc() |> Integer.to_string()
  defp liters_hint(_), do: "-"

  defp pretty_kw(nil), do: "-"
  defp pretty_kw(value) when is_number(value), do: Float.round(value * 1.0, 1)
  defp pretty_kw(_value), do: "-"

  defp banner_text(""), do: "unknown"

  defp banner_text(text),
    do: text |> String.replace("_", " ") |> String.capitalize()

  defp attention_border([]), do: "border-success/70"
  defp attention_border(_), do: "border-warning/60"

  defp attention_dot([]), do: "bg-success"
  defp attention_dot(_entries), do: "bg-warning animate-pulse"
end
