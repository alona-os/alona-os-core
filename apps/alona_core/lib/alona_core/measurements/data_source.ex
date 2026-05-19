defmodule AlonaCore.Measurements.DataSource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_sources" do
    belongs_to :property, AlonaCore.Topology.Property
    field :name, :string
    field :source_type, :string
    field :integration_type, :string
    field :status, :string, default: "active"
    field :last_seen_at, :utc_datetime_usec
    field :metadata, :map, default: %{}
    timestamps(type: :utc_datetime_usec)

    has_many :devices, AlonaCore.Measurements.Device
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:property_id, :name, :source_type, :integration_type, :status, :last_seen_at, :metadata])
    |> validate_required([:property_id, :name, :source_type, :status])
  end
end
