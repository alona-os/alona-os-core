defmodule AlonaUiWeb.TasksLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.Repo
  alias AlonaCore.Tasks
  alias AlonaCore.Tasks.Task

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Tasks")
      |> assign(:active_nav, :tasks)

    {:ok, reload(socket)}
  end

  defp reload(socket) do
    pending =
      Tasks.list_tasks()
      |> Enum.reject(fn t -> t.status == "completed" end)

    socket
    |> assign(:tasks, pending)
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def handle_event("create_task", params, socket) do
    title = params["title"] |> to_string() |> String.trim()

    if title == "" do
      {:noreply, put_flash(socket, :error, "title required")}
    else
      attrs = %{
        title: title,
        description: optional_string(params["description"]),
        status: "pending",
        priority: pick_priority(params["priority"]),
        due_at: parse_due(params["due_date"]),
        source_type: "manual"
      }

      Tasks.create_basic_task!(attrs)

      {:noreply,
       socket
       |> put_flash(:info, "task created")
       |> reload()}
    end
  end

  @impl true
  def handle_event("complete", %{"id" => id}, socket) do
    parsed = Integer.parse(to_string(id))

    if parsed == :error do
      {:noreply, put_flash(socket, :error, "invalid task id")}
    else
      {tid, _} = parsed

      case Repo.get(Task, tid) do
        nil ->
          {:noreply, put_flash(socket, :error, "task not found")}

        task ->
          if task.status == "completed" do
            {:noreply, put_flash(socket, :info, "already completed")}
          else
            Tasks.mark_completed!(task)
            {:noreply, socket |> put_flash(:info, "marked complete") |> reload()}
          end
      end
    end
  end

  defp optional_string(nil), do: nil

  defp optional_string(bin) when is_binary(bin) do
    trimmed = String.trim(bin)
    if(trimmed == "", do: nil, else: trimmed)
  end

  defp pick_priority(nil), do: "medium"

  defp pick_priority(bin) when is_binary(bin) do
    v = bin |> String.downcase()

    cond do
      v in ["low", "medium", "high"] -> v
      true -> "medium"
    end
  end

  defp pick_priority(other), do: pick_priority(to_string(other))

  defp parse_due(nil), do: nil

  defp parse_due(bin) when is_binary(bin) do
    trimmed = String.trim(bin)
    if trimmed == "", do: nil, else: date_to_end_of_utc(trimmed)
  end

  defp parse_due(other), do: parse_due(to_string(other))

  defp date_to_end_of_utc(trimmed) do
    case Date.from_iso8601(trimmed) do
      {:ok, d} ->
        {:ok, at} = DateTime.new(d, ~T[23:59:59], "Etc/UTC")
        at

      {:error, _} ->
        nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">operations rail</p>

      <h1 class="text-3xl font-semibold tracking-tight">Tasks</h1>

      <p class="text-sm text-base-content/65">pending & scheduled work surfaced from MVP seeds.</p>
    </section>

    <section class="mt-8 grid gap-6 lg:grid-cols-5">
      <article class="rounded-xl border border-base-200 bg-base-100 p-5 shadow-sm lg:col-span-2">
        <p class="text-sm font-semibold">quick add</p>

        <form id="task-form" phx-submit="create_task" class="mt-4 space-y-3">
          <div>
            <label class="text-xs uppercase text-base-content/55" for="task-title-input">title</label>

            <input
              id="task-title-input"
              required
              name="title"
              class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
              type="text"
              placeholder="e.g. bleed radiators"
            />
          </div>

          <div>
            <label class="text-xs uppercase text-base-content/55" for="task-description-input">notes</label>

            <textarea
              id="task-description-input"
              rows="3"
              name="description"
              class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
            />
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div>
              <label class="text-xs uppercase text-base-content/55" for="task-priority-select">priority</label>

              <select
                id="task-priority-select"
                name="priority"
                class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm capitalize"
              >
                <option value="low">low</option>

                <option value="medium" selected>medium</option>

                <option value="high">high</option>
              </select>
            </div>

            <div>
              <label class="text-xs uppercase text-base-content/55" for="task-date-input">due date</label>

              <input
                id="task-date-input"
                name="due_date"
                type="date"
                class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
              />
            </div>
          </div>

          <button class="btn btn-primary btn-sm mt-2" type="submit">add task</button>
        </form>
      </article>

      <div class="space-y-3 lg:col-span-3">
        <%= if @tasks == [] do %>
          <p class="rounded-xl border border-dashed border-base-300 bg-base-100 p-8 text-center text-sm text-base-content/60">
            no open tasks · add one alongside or seed more data with `mix ecto.seed`.
          </p>
        <% else %>
          <%= for task <- @tasks do %>
            <div class="space-y-2">
              <.task_item task={task} />

              <%= if task.status != "completed" do %>
                <button
                  class="btn btn-ghost btn-xs"
                  phx-click="complete"
                  phx-value-id={task.id}
                  type="button"
                >
                  mark done
                </button>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
    </section>
    """
  end
end
