defmodule AlonaCore.Events.EventLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_links" do
    belongs_to :event, AlonaCore.Events.Event
    belongs_to :entity, AlonaCore.Topology.Entity
    field :relation_type, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:event_id, :entity_id, :relation_type])
    |> validate_required([:event_id, :entity_id, :relation_type])
  end
end
