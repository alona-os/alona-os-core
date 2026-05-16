defmodule AlonaCore.Tasks do
  import Ecto.Query
  alias AlonaCore.{Broadcast, Repo}
  alias AlonaCore.Tasks.Task

  def list_tasks do
    Repo.all(from(t in Task, order_by: [asc: t.due_at, asc: t.id]))
  end

  def create_basic_task!(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert!()
    |> tap(fn _ -> Broadcast.broadcast_dashboard() end)
  end

  def mark_completed!(task) do
    now = DateTime.utc_now(:microsecond)

    task
    |> Task.changeset(%{status: "completed", completed_at: now})
    |> Repo.update!()
    |> tap(fn updated ->
      AlonaCore.Events.create_event!(
        %{
          event_type: "task",
          severity: "success",
          title: "Task completed",
          description: updated.title,
          occurred_at: now,
          source_type: "task",
          source_id: to_string(task.id),
          actor_type: "user",
          actor_id: nil,
          payload: %{task_id: task.id}
        }
      )
    end)
  end
end
