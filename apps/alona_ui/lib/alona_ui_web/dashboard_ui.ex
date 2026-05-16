defmodule AlonaUiWeb.DashboardUi do
  @moduledoc """
  reusable HEEx function components mirrored loosely from the v0 dashboard cards.
  """
  use Phoenix.Component

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

  def metric_card(assigns) do
    assigns =
      assigns
      |> assign(:border_tone, Map.get(@metric_borders, assigns.status, "border-base-300"))
      |> assign(:shown, format_reading(assigns.value))

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

        <span :if={@trend_label} class="text-xs font-medium text-success">
          {@trend_label}
        </span>
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
      |> assign(:sensor_tone, assigns.sensor_status == :online && "text-success" || "text-error")
      |> assign(:sensor_note, assigns.sensor_status == :online && "online" || "offline")

    ~H"""
    <article class="rounded-xl border border-base-300 bg-base-100 p-4 shadow-sm">
      <div class="mb-3 flex items-center justify-between">
        <h3 class="text-sm font-semibold">{@name}</h3>

        <p class={["text-xs font-semibold", @sensor_tone]}>
          {@sensor_note}
        </p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <p class="text-lg font-semibold">{@temp_text}</p>

          <p class="text-xs text-base-content/55">temperature (°c)</p>
        </div>

        <div>
          <p class="text-lg font-semibold">{@humi_text}</p>

          <p class="text-xs text-base-content/55">humidity (%)</p>
        </div>
      </div>

      <p class="mt-3 border-t border-base-200 pt-3 text-xs text-base-content/55">{last_seen_text(@last_seen)}</p>
    </article>
    """
  end

  attr :title, :string, required: true

  attr :message, :string, default: nil

  attr :severity, :string, default: "info"

  attr :compact, :boolean, default: false

  def alert_banner(assigns) do
    assigns = assign(assigns, envelope: envelope_style(assigns.severity))

    ~H"""
    <div class={[
      "rounded-lg border p-4 shadow-sm",
      assigns.compact && "py-3",
      assigns.envelope
    ]}>
      <p class="text-sm font-semibold">{@title}</p>

      <p :if={@message} class="mt-1 text-xs text-base-content/65">{@message}</p>
    </div>
    """
  end

  attr :task, :any, required: true

  attr :compact, :boolean, default: false

  def task_item(assigns) do
    assigns = assign(assigns, :badge, badge_for_priority(assigns.task.priority))

    ~H"""
    <div class={[
      "rounded-lg border border-base-300 bg-base-100 p-3 shadow-sm",
      assigns.compact && "py-2"
    ]}>
      <div class="flex justify-between gap-4">
        <div class="min-w-0">
          <p class="truncate font-medium">{@task.title}</p>

          <p class="mt-1 text-xs text-base-content/55">
            {readable_status(@task.status)}
            <span :if={@task.due_at}>· due {Calendar.strftime(@task.due_at, "%d %b")}</span>
          </p>
        </div>

        <span class={"badge badge-soft capitalize #{@badge}"}>
          {@task.priority}
        </span>
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

  defp last_seen_text(%DateTime{} = dt), do: "last updated #{Calendar.strftime(dt, "%H:%M:%S utc")}"

  defp last_seen_text(_), do: "last updated unavailable"

  defp envelope_style("warning"), do: "border-warning bg-warning/10"
  defp envelope_style("error"), do: "border-error bg-error/10"
  defp envelope_style(_), do: "border-base-300 bg-base-100"

  defp readable_status(nil), do: "unknown"

  defp readable_status(status), do: status |> to_string() |> String.capitalize()

  defp badge_for_priority("high"), do: "badge-error"
  defp badge_for_priority("medium"), do: "badge-warning"
  defp badge_for_priority(_other), do: "badge-ghost"

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
