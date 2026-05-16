defmodule AlonaCore.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :priority, :string, default: "medium"
    field :due_at, :utc_datetime_usec
    field :scheduled_for, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :source_type, :string
    field :source_id, :string
    field :recurrence_rule, :string
    field :estimated_duration_minutes, :integer
    timestamps(type: :utc_datetime_usec)

    has_many :links, AlonaCore.Tasks.TaskLink
    has_many :checklist_items, AlonaCore.Tasks.TaskChecklistItem
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :priority,
      :due_at,
      :scheduled_for,
      :completed_at,
      :source_type,
      :source_id,
      :recurrence_rule,
      :estimated_duration_minutes
    ])
    |> validate_required([:title, :status, :priority])
  end
end
