defmodule AlonaCore.Tasks.TaskLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_links" do
    belongs_to :task, AlonaCore.Tasks.Task
    belongs_to :entity, AlonaCore.Topology.Entity
    field :relation_type, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:task_id, :entity_id, :relation_type])
    |> validate_required([:task_id, :entity_id, :relation_type])
  end
end
