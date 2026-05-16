defmodule AlonaCore.Topology.Domain do
  use Ecto.Schema
  import Ecto.Changeset

  schema "domains" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :status, :string, default: "active"
    belongs_to :parent, __MODULE__, foreign_key: :parent_domain_id
    timestamps(type: :utc_datetime_usec)

    has_many :children, __MODULE__, foreign_key: :parent_domain_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :slug, :description, :parent_domain_id, :status])
    |> validate_required([:name, :slug, :status])
    |> foreign_key_constraint(:parent_domain_id)
  end
end
