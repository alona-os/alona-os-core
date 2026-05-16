defmodule AlonaCore.Topology.EntityLink do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entity_links" do
    belongs_to :source_entity, AlonaCore.Topology.Entity, foreign_key: :source_entity_id
    belongs_to :target_entity, AlonaCore.Topology.Entity, foreign_key: :target_entity_id
    field :relation_type, :string
    field :valid_from, :utc_datetime_usec
    field :valid_to, :utc_datetime_usec
    field :notes, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:source_entity_id, :target_entity_id, :relation_type, :valid_from, :valid_to, :notes])
    |> validate_required([:source_entity_id, :target_entity_id, :relation_type])
  end
end
