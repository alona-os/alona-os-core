defmodule AlonaCore.Resources.ResourceType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resource_types" do
    field :name, :string
    field :base_unit, :string
    field :category, :string
    timestamps(type: :utc_datetime_usec)

    has_many :stores, AlonaCore.Resources.ResourceStore
    has_many :flows, AlonaCore.Resources.ResourceFlow
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :base_unit, :category])
    |> validate_required([:name, :base_unit])
  end
end
