defmodule AlonaCore.Topology.Property do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "active"
    field :metadata, :map, default: %{}
    timestamps(type: :utc_datetime_usec)

    has_many :locations, AlonaCore.Topology.Location
    has_many :entities, AlonaCore.Topology.Entity
    has_many :data_sources, AlonaCore.Measurements.DataSource
    has_many :measurement_streams, AlonaCore.Measurements.MeasurementStream
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :slug, :status, :metadata])
    |> validate_required([:name, :slug, :status])
    |> unique_constraint(:slug)
  end
end
