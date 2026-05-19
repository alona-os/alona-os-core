defmodule AlonaCore.Topology.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "locations" do
    field :name, :string
    field :type, :string
    field :description, :string
    belongs_to :property, AlonaCore.Topology.Property
    belongs_to :parent, __MODULE__, foreign_key: :parent_location_id
    timestamps(type: :utc_datetime_usec)

    has_many :children, __MODULE__, foreign_key: :parent_location_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :type, :description, :property_id, :parent_location_id])
    |> validate_required([:name, :type, :property_id])
    |> foreign_key_constraint(:parent_location_id)
  end
end
