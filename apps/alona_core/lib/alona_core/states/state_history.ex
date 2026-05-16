defmodule AlonaCore.States.StateHistory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "state_histories" do
    belongs_to :entity, AlonaCore.Topology.Entity
    field :state_key, :string
    field :old_value, :string
    field :new_value, :string
    field :changed_at, :utc_datetime_usec
    field :source_type, :string
    field :source_id, :string
    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:entity_id, :state_key, :old_value, :new_value, :changed_at, :source_type, :source_id])
    |> validate_required([:entity_id, :state_key, :changed_at])
  end
end
