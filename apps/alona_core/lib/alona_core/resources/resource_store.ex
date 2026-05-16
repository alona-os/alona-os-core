defmodule AlonaCore.Resources.ResourceStore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resource_stores" do
    belongs_to :entity, AlonaCore.Topology.Entity
    belongs_to :resource_type, AlonaCore.Resources.ResourceType
    field :capacity, :decimal
    field :unit, :string
    field :current_estimated_amount, :decimal
    field :min_safe_amount, :decimal
    field :max_safe_amount, :decimal
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :entity_id,
      :resource_type_id,
      :capacity,
      :unit,
      :current_estimated_amount,
      :min_safe_amount,
      :max_safe_amount
    ])
    |> validate_required([:entity_id, :resource_type_id, :unit])
  end
end
