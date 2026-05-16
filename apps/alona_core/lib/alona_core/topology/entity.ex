defmodule AlonaCore.Topology.Entity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entities" do
    field :name, :string
    field :aliases, {:array, :string}, default: []
    field :description, :string
    field :entity_type, :string
    field :status, :string, default: "active"
    field :installed_at, :utc_datetime_usec
    field :retired_at, :utc_datetime_usec
    field :notes, :string
    field :metadata, :map, default: %{}

    belongs_to :primary_domain, AlonaCore.Topology.Domain, foreign_key: :primary_domain_id
    belongs_to :location, AlonaCore.Topology.Location
    belongs_to :parent, __MODULE__, foreign_key: :parent_entity_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :name,
      :aliases,
      :description,
      :entity_type,
      :status,
      :installed_at,
      :retired_at,
      :notes,
      :metadata,
      :primary_domain_id,
      :location_id,
      :parent_entity_id
    ])
    |> validate_required([:name, :entity_type, :status])
    |> validate_length(:aliases, max: 50)
    |> foreign_key_constraint(:primary_domain_id)
    |> foreign_key_constraint(:location_id)
    |> foreign_key_constraint(:parent_entity_id)
  end
end
