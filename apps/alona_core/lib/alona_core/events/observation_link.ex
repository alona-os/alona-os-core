defmodule AlonaCore.Events.ObservationLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "observation_links" do
    belongs_to :observation, AlonaCore.Events.Observation, primary_key: true
    belongs_to :entity, AlonaCore.Topology.Entity, primary_key: true
    field :relation_type, :string, primary_key: true
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:observation_id, :entity_id, :relation_type])
    |> validate_required([:observation_id, :entity_id, :relation_type])
  end
end
