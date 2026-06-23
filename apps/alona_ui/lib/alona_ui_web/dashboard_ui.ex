defmodule AlonaUiWeb.DashboardUi do
  @moduledoc """
  reusable HEEx function components for dashboard cards.
  """
  use Phoenix.Component

  import AlonaUiWeb.CoreComponents

  @metric_borders %{
    "normal" => "border-base-300",
    "warning" => "border-warning",
    "error" => "border-error",
    "success" => "border-success"
  }

  attr :title, :string, required: true

  attr :value, :any, required: true

  attr :unit, :string, default: nil

  attr :subtitle, :string, default: nil

  attr :status, :string, default: "normal"

  attr :trend_label, :string, default: nil

  attr :icon, :string, default: nil

  def metric_card(assigns) do
    assigns =
      assigns
      |> assign(:border_tone, Map.get(@metric_borders, assigns.status, "border-base-300"))
      |> assign(:shown, format_reading(assigns.value))
      |> assign(:show_aside?, assigns.icon != nil or assigns.trend_label != nil)

    ~H"""
    <article class={"rounded-xl border bg-base-100 shadow-sm border-l-4 p-4 #{@border_tone}"}>
      <div class="flex items-start justify-between gap-4">
        <div class="space-y-1">
          <p class="text-sm text-base-content/60">{@title}</p>

          <div class="flex items-baseline gap-2">
            <span class="text-2xl font-semibold tracking-tight">{@shown}</span>

            <span :if={@unit} class="text-sm text-base-content/55">
              {@unit}
            </span>
          </div>

          <p :if={@subtitle} class="text-xs text-base-content/55">{@subtitle}</p>
        </div>

        <div :if={@show_aside?} class="flex flex-col items-end gap-2">
          <.icon :if={@icon} name={@icon} class="size-5 text-base-content/60" />
          <span :if={@trend_label} class="text-xs font-medium text-success">
            {@trend_label}
          </span>
        </div>
      </div>
    </article>
    """
  end

  attr :name, :string, required: true

  attr :temperature, :any, default: nil

  attr :humidity, :any, default: nil

  attr :sensor_status, :atom, required: true

  attr :last_seen, :any, default: nil

  def room_card(assigns) do
    assigns =
      assigns
      |> assign(:temp_text, format_reading(assigns.temperature))
      |> assign(:humi_text, format_reading(assigns.humidity))
      |> assign(
        :sensor_tone,
        (assigns.sensor_status == :online && "text-success") || "text-error"
      )
      |> assign(:sensor_note, (assigns.sensor_status == :online && "online") || "offline")

    ~H"""
    <article class="rounded-xl border border-base-300 bg-base-100 p-4 shadow-sm">
      <div class="mb-3 flex items-center justify-between">
        <h3 class="text-sm font-semibold">{@name}</h3>

        <p class={["text-xs font-semibold", @sensor_tone]}>
          {@sensor_note}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="flex items-center gap-2">
          <div class="rounded-md bg-base-200 p-2">
            <.icon name="hero-sun-micro" class="size-4 text-[oklch(55%_0.12_25)]" />
          </div>
          <div>
            <div class="flex items-baseline gap-1">
              <span class="text-lg font-semibold">{@temp_text}</span>
              <span class="text-xs text-base-content/55">°C</span>
            </div>
            <span class="text-xs text-base-content/55">Temperature</span>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <div class="rounded-md bg-base-200 p-2">
            <.icon name="hero-eye-dropper-micro" class="size-4 text-[oklch(60%_0.15_220)]" />
          </div>
          <div>
            <div class="flex items-baseline gap-1">
              <span class="text-lg font-semibold">{@humi_text}</span>
              <span class="text-xs text-base-content/55">%</span>
            </div>
            <span class="text-xs text-base-content/55">Humidity</span>
          </div>
        </div>
      </div>

      <p class="mt-3 border-t border-base-200 pt-3 text-xs text-base-content/55">
        {last_seen_text(@last_seen)}
      </p>
    </article>
    """
  end

  attr :title, :string, required: true

  attr :message, :string, default: nil

  attr :severity, :string, default: "info"

  attr :compact, :boolean, default: false

  attr :occurred_at, :any, default: nil

  def alert_banner(%{compact: true} = assigns) do
    assigns =
      assigns
      |> assign(:icon_name, severity_row_icon(assigns.severity))
      |> assign(:icon_class, severity_row_icon_class(assigns.severity))
      |> assign(:ago_min, minutes_ago(assigns.occurred_at))

    ~H"""
    <div class="flex items-center gap-2 py-2">
      <.icon name={@icon_name} class={["size-4 shrink-0", @icon_class]} />
      <span class="flex-1 truncate text-sm">{@title}</span>
      <span :if={@ago_min != nil} class="shrink-0 text-xs text-base-content/60">{@ago_min}m ago</span>
    </div>
    """
  end

  def alert_banner(assigns) do
    assigns =
      assigns
      |> assign(:surface, alert_card_surface(assigns.severity))
      |> assign(:icon_name, severity_card_icon(assigns.severity))
      |> assign(:icon_class, severity_row_icon_class(assigns.severity))
      |> assign(:ago_min, minutes_ago(assigns.occurred_at))

    ~H"""
    <div class={"flex items-start gap-3 rounded-lg border p-3 #{@surface}"}>
      <.icon name={@icon_name} class={["mt-0.5 size-5 shrink-0", @icon_class]} />
      <div class="min-w-0 flex-1">
        <p class="text-sm font-medium">{@title}</p>
        <p :if={not blank?(@message)} class="mt-1 text-xs text-base-content/60">{@message}</p>
        <p :if={@ago_min != nil} class="mt-1 text-xs text-base-content/60">{@ago_min}m ago</p>
      </div>
    </div>
    """
  end

  attr :task, :any, required: true

  attr :compact, :boolean, default: false

  def task_item(%{compact: true} = assigns) do
    assigns =
      assigns
      |> assign(:due_txt, task_due_label(assigns.task))
      |> assign(:status_ic, task_status_row_icon(assigns.task.status))
      |> assign(:status_tn, task_status_row_class(assigns.task.status))

    ~H"""
    <div class="flex items-center gap-2 py-2">
      <.icon name={@status_ic} class={["size-4 shrink-0", @status_tn]} />
      <span class="flex-1 truncate text-sm">{@task.title}</span>
      <span class="shrink-0 text-xs text-base-content/60">{@due_txt}</span>
    </div>
    """
  end

  def task_item(assigns) do
    task = assigns.task
    due_txt = task_due_label(task)
    src_lbl = source_label(task)

    assigns =
      assigns
      |> assign(:status_ic, task_status_row_icon(task.status))
      |> assign(:status_tn, task_status_row_class(task.status))
      |> assign(:due_txt, due_txt)
      |> assign(:src_lbl, src_lbl)
      |> assign(:priority_tone, priority_row_tone(task.priority))
      |> assign(:show_meta?, due_txt != "" || src_lbl != nil)

    ~H"""
    <div class="flex items-start gap-3 rounded-lg border border-base-300 bg-base-100 p-3">
      <.icon name={@status_ic} class={["mt-0.5 size-5 shrink-0", @status_tn]} />
      <div class="min-w-0 flex-1">
        <div class="flex flex-wrap items-center gap-2">
          <p class="text-sm font-medium">{@task.title}</p>
          <span class={[
            "rounded-md border-0 px-2 py-0.5 text-xs font-medium capitalize",
            @priority_tone
          ]}>
            {@task.priority}
          </span>
        </div>
        <p :if={not blank?(@task.description)} class="mt-1 line-clamp-2 text-xs text-base-content/60">
          {@task.description}
        </p>
        <div
          :if={@show_meta?}
          class="mt-2 flex flex-wrap items-center gap-3 text-xs text-base-content/60"
        >
          <span :if={@due_txt != ""}>Due: {@due_txt}</span>
          <span :if={@src_lbl} class="capitalize">Source: {@src_lbl}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :event, :any, required: true

  def timeline_item(assigns) do
    assigns =
      assigns
      |> assign(:kind, humanize(assigns.event.event_type))
      |> assign(:dot, dot(assigns.event.severity))

    ~H"""
    <article class="border-l border-base-200 py-4 pl-4">
      <div class="flex items-start gap-4">
        <div class={"mt-1 h-2 w-2 shrink-0 rounded-full #{@dot}"} />

        <div class="flex-1">
          <div class="flex items-start justify-between gap-6">
            <div>
              <p class="text-xs uppercase tracking-wide text-base-content/55">
                {@kind}
              </p>

              <p class="text-sm font-semibold">{@event.title}</p>

              <p :if={@event.description} class="mt-1 text-xs text-base-content/60">
                {@event.description}
              </p>
            </div>

            <p class="whitespace-nowrap text-xs text-base-content/55">
              {Calendar.strftime(@event.occurred_at, "%d %b %H:%M")}
            </p>
          </div>
        </div>
      </div>
    </article>
    """
  end

  attr :tone, :string, default: "neutral"

  attr :label, :string, required: true

  def status_badge(assigns) do
    assigns = assign(assigns, palette: palette(assigns.tone))

    ~H"""
    <span class={"inline-flex items-center gap-2 rounded-full border px-2 py-1 text-[11px] font-semibold #{@palette}"}>
      <span class="h-1.5 w-1.5 rounded-full bg-current/75"></span>
      {@label}
    </span>
    """
  end

  defp format_reading(nil), do: "-"

  defp format_reading(%Decimal{} = d), do: Decimal.to_string(d)

  defp format_reading(val) when is_float(val) do
    "#{Float.round(val, 1)}"
  end

  defp format_reading(val) when is_integer(val), do: Integer.to_string(val)

  defp format_reading(val), do: to_string(val)

  defp last_seen_text(nil), do: "no measurement yet"

  defp last_seen_text(%DateTime{} = dt),
    do: "last updated #{Calendar.strftime(dt, "%H:%M:%S utc")}"

  defp last_seen_text(_), do: "last updated unavailable"

  defp alert_card_surface("error"), do: "border-error/30 bg-error/10"
  defp alert_card_surface("warning"), do: "border-warning/30 bg-warning/10"
  defp alert_card_surface("info"), do: "border-info/30 bg-info/10"
  defp alert_card_surface(_), do: "border-base-300 bg-base-100"

  defp severity_card_icon("error"), do: "hero-exclamation-circle-mini"
  defp severity_card_icon("warning"), do: "hero-exclamation-triangle-mini"
  defp severity_card_icon(_), do: "hero-information-circle-mini"

  defp severity_row_icon("error"), do: "hero-exclamation-circle-micro"
  defp severity_row_icon("warning"), do: "hero-exclamation-triangle-micro"
  defp severity_row_icon(_), do: "hero-information-circle-micro"

  defp severity_row_icon_class("error"), do: "text-error"
  defp severity_row_icon_class("warning"), do: "text-warning"
  defp severity_row_icon_class(_), do: "text-info"

  defp minutes_ago(%DateTime{} = at) do
    DateTime.diff(DateTime.utc_now(:microsecond), at, :minute) |> max(0)
  end

  defp minutes_ago(_), do: nil

  defp task_status_row_icon("completed"), do: "hero-check-circle-micro"
  defp task_status_row_icon("in-progress"), do: "hero-clock-micro"
  defp task_status_row_icon("in_progress"), do: "hero-clock-micro"
  defp task_status_row_icon("overdue"), do: "hero-exclamation-circle-micro"
  defp task_status_row_icon(_), do: "hero-stop-circle-micro"

  defp task_status_row_class("completed"), do: "text-success"
  defp task_status_row_class("in-progress"), do: "text-info"
  defp task_status_row_class("in_progress"), do: "text-info"
  defp task_status_row_class("overdue"), do: "text-error"
  defp task_status_row_class(_), do: "text-base-content/60"

  defp task_due_label(%{due_at: nil}), do: ""

  defp task_due_label(%{due_at: %DateTime{} = due_at}) do
    today = Date.utc_today()
    due_date = DateTime.to_date(due_at)
    diff = Date.diff(due_date, today)

    cond do
      diff == 0 ->
        "Today"

      diff == 1 ->
        "Tomorrow"

      diff == -1 ->
        "Yesterday"

      diff < -1 ->
        "#{abs(diff)} days overdue"

      diff <= 7 ->
        "In #{diff} days"

      true ->
        Calendar.strftime(due_date, "%b %d")
    end
  end

  defp task_due_label(_), do: ""

  defp source_label(%{source_type: t}) when is_binary(t) and t != "",
    do: t |> String.replace("_", " ")

  defp source_label(_), do: nil

  defp priority_row_tone("high"), do: "bg-error/20 text-error"
  defp priority_row_tone("medium"), do: "bg-warning/20 text-warning"
  defp priority_row_tone(_), do: "bg-base-200 text-base-content/70"

  defp blank?(nil), do: true
  defp blank?(s) when is_binary(s), do: String.trim(s) == ""
  defp blank?(_), do: false

  defp dot(nil), do: "bg-base-content/35"

  defp dot("error"), do: "bg-error"
  defp dot("warning"), do: "bg-warning"
  defp dot("success"), do: "bg-success"
  defp dot(_), do: "bg-info"

  defp palette("warning"), do: "border-warning text-warning bg-warning/10"

  defp palette("critical"), do: "border-error text-error bg-error/10"

  defp palette("neutral"), do: "border-base-300 text-base-content/70 bg-base-100"

  defp palette(_), do: "border-success text-success bg-success/10"

  defp humanize(nil), do: "event"

  defp humanize(bin) when is_binary(bin),
    do: bin |> String.replace("_", " ") |> String.downcase()

  defp humanize(_), do: "event"
end
