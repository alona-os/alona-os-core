defmodule AlonaCore.States.EntityState do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "entity_states" do
    belongs_to :entity, AlonaCore.Topology.Entity, primary_key: true
    field :state_key, :string, primary_key: true
    field :state_value, :string
    field :updated_at_utc, :utc_datetime_usec
    belongs_to :source_event, AlonaCore.Events.Event, foreign_key: :source_event_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:entity_id, :state_key, :state_value, :updated_at_utc, :source_event_id])
    |> validate_required([:entity_id, :state_key, :state_value, :updated_at_utc])
    |> assoc_constraint(:entity)
  end
end
