defmodule AlonaCore.Measurements.MetricDefinition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "metric_definitions" do
    field :name, :string
    field :unit, :string
    field :value_type, :string
    field :category, :string
    timestamps(type: :utc_datetime_usec)

    has_many :streams, AlonaCore.Measurements.MeasurementStream, foreign_key: :metric_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :unit, :value_type, :category])
    |> validate_required([:name, :unit, :value_type])
  end
end
