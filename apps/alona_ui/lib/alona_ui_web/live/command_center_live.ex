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
     |> assign(:page_title, "Command Center")
     |> assign(:active_nav, :command_center)
     |> reload_assigns()}
  end

  defp reload_assigns(socket) do
    binds = DashboardPresenter.command_center_binds()
    overdue = Enum.filter(binds.today_tasks, &(&1.status == "overdue"))

    attention =
      Enum.map(binds.alerts, fn evt ->
        %{
          kind: :alert,
          title: evt.title,
          subtitle: evt.description,
          severity: evt.severity,
          occurred_at: evt.occurred_at
        }
      end)
      |> Enum.concat(Enum.map(Enum.take(overdue, 3), fn task -> %{kind: :task, task: task} end))
      |> Enum.take(5)

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
    <div class="space-y-6">
      <div>
        <h1 class="text-2xl font-semibold tracking-tight">Command Center</h1>
        <p class="text-sm text-base-content/60">Overview of your home systems and operations</p>
      </div>

      <div class="grid grid-cols-12 gap-6">
        <div class="col-span-12 space-y-6 lg:col-span-8">
          <section>
            <h2 class="mb-3 text-sm font-medium text-base-content/60">Resources Snapshot</h2>

            <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
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

          <section>
            <h2 class="mb-3 text-sm font-medium text-base-content/60">Indoor Environment</h2>

            <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
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
            <section>
              <h2 class="mb-3 text-sm font-medium text-base-content/60">Active Alerts</h2>

              <div class="space-y-2">
                <%= for alert <- @alerts do %>
                  <.alert_banner
                    title={alert.title}
                    message={alert.description}
                    severity={alert.severity || "warning"}
                    occurred_at={alert.occurred_at}
                  />
                <% end %>
              </div>
            </section>
          <% end %>

          <section>
            <div class="mb-3 flex items-center justify-between">
              <h2 class="text-sm font-medium text-base-content/60">Today's Tasks</h2>

              <span class="text-xs text-base-content/60">
                <span :if={overdue_count(@today_tasks) > 0} class="mr-2 text-error">
                  <%= overdue_count(@today_tasks) %> overdue
                </span>
                <%= length(@today_tasks) %> total
              </span>
            </div>

            <div class="space-y-2">
              <%= if @today_tasks == [] do %>
                <div class="rounded-xl border border-dashed border-base-300 bg-base-100 py-8 text-center">
                  <p class="text-sm text-base-content/60">No tasks for today</p>
                </div>
              <% else %>
                <%= for task <- Enum.take(@today_tasks, 4) do %>
                  <.task_item task={task} />
                <% end %>
              <% end %>
            </div>
          </section>

          <section>
            <h2 class="mb-3 text-sm font-medium text-base-content/60">System Status</h2>

            <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
              <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
                <div class="px-4 pb-4 pt-4">
                  <div class="mb-1 flex items-center gap-2">
                    <div class="size-2 rounded-full bg-success"></div>
                    <span class="text-xs text-base-content/60">Automations</span>
                  </div>
                  <p class="text-lg font-semibold">0 active</p>
                </div>
              </article>

              <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
                <div class="px-4 pb-4 pt-4">
                  <div class="mb-1 flex items-center gap-2">
                    <div class="size-2 rounded-full bg-success"></div>
                    <span class="text-xs text-base-content/60">Security</span>
                  </div>
                  <p class="text-lg font-semibold">All armed</p>
                </div>
              </article>

              <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
                <div class="px-4 pb-4 pt-4">
                  <div class="mb-1 flex items-center gap-2">
                    <div class={"size-2 rounded-full #{gen_status_dot(@gen_status)}"}></div>
                    <span class="text-xs text-base-content/60">Generator</span>
                  </div>
                  <p class="text-lg font-semibold"><%= banner_text(@gen_status) %></p>
                </div>
              </article>

              <article class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
                <div class="px-4 pb-4 pt-4">
                  <div class="mb-1 flex items-center gap-2">
                    <div class="size-2 rounded-full bg-success"></div>
                    <span class="text-xs text-base-content/60">Network</span>
                  </div>
                  <p class="text-lg font-semibold">Online</p>
                </div>
              </article>
            </div>
          </section>
        </div>

        <div class="col-span-12 space-y-6 lg:col-span-4">
          <section class={[
            "flex flex-col gap-6 rounded-xl border bg-base-100 py-6 shadow-sm",
            if(@attention == [], do: "border-base-300", else: "border-warning/50")
          ]}>
            <div class="px-6 pb-3">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <div :if={@attention != []} class="size-2 animate-pulse rounded-full bg-warning"></div>
                  <h3 class="text-sm font-medium">Needs Attention</h3>
                </div>
                <span class="text-xs text-base-content/60"><%= length(@attention) %></span>
              </div>
            </div>

            <div class="px-6">
              <%= if @attention == [] do %>
                <div class="py-4 text-center">
                  <div class="mx-auto mb-2 flex size-10 items-center justify-center rounded-full bg-success/10">
                    <div class="size-3 rounded-full bg-success"></div>
                  </div>
                  <p class="text-sm text-base-content/60">All systems normal</p>
                </div>
              <% else %>
                <div class="space-y-3">
                  <%= for entry <- @attention do %>
                    <%= if entry.kind == :alert do %>
                      <.alert_banner
                        title={entry.title}
                        message={entry.subtitle}
                        severity={entry.severity || "warning"}
                        occurred_at={entry.occurred_at}
                        compact
                      />
                    <% else %>
                      <.task_item task={entry.task} compact />
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
          </section>

          <section class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
            <div class="border-b border-base-200 px-4 pb-3 pt-4">
              <h3 class="text-sm font-medium">Recent Activity</h3>
            </div>

            <div class="px-4 pb-4 pt-2">
              <div class="space-y-0">
                <%= for event <- Enum.take(@timeline, 6) do %>
                  <.timeline_item event={event} />
                <% end %>
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-base-300 bg-base-100 shadow-sm">
            <div class="border-b border-base-200 px-4 pb-3 pt-4">
              <h3 class="text-sm font-medium">Quick Actions</h3>
            </div>

            <div class="p-4">
              <div class="grid grid-cols-2 gap-2">
                <.link navigate={~p"/tasks"} class="quick-action-tile">
                  <.icon name="hero-plus-micro" class="size-4" />
                  <span class="text-xs">Add Task</span>
                </.link>

                <.link navigate={~p"/finance"} class="quick-action-tile">
                  <.icon name="hero-banknotes-micro" class="size-4" />
                  <span class="text-xs">Log Expense</span>
                </.link>

                <.link navigate={~p"/timeline"} class="quick-action-tile">
                  <.icon name="hero-eye-micro" class="size-4" />
                  <span class="text-xs">Observation</span>
                </.link>

                <.link navigate={~p"/protocols"} class="quick-action-tile">
                  <.icon name="hero-document-text-micro" class="size-4" />
                  <span class="text-xs">Protocol</span>
                </.link>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
    """
  end

  defp gen_status_dot(status_text) do
    t = status_text |> String.downcase()

    cond do
      t == "" or t == "unknown" -> "bg-base-content/40"
      String.contains?(t, "standby") or String.contains?(t, "off") -> "bg-base-content/50"
      true -> "bg-success"
    end
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
end
