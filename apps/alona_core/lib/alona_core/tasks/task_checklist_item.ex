defmodule AlonaCore.Tasks.TaskChecklistItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_checklist_items" do
    belongs_to :task, AlonaCore.Tasks.Task
    field :title, :string
    field :status, :string, default: "pending"
    field :sort_order, :integer, default: 0
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:task_id, :title, :status, :sort_order])
    |> validate_required([:task_id, :title, :status])
  end
end
