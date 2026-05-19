defmodule AlonaCore.Measurements.MeasurementStream do
  use Ecto.Schema
  import Ecto.Changeset

  schema "measurement_streams" do
    belongs_to :property, AlonaCore.Topology.Property
    field :name, :string
    field :slug, :string
    belongs_to :metric, AlonaCore.Measurements.MetricDefinition, foreign_key: :metric_id
    belongs_to :source_entity, AlonaCore.Topology.Entity, foreign_key: :source_entity_id
    belongs_to :subject_entity, AlonaCore.Topology.Entity, foreign_key: :subject_entity_id
    belongs_to :data_source, AlonaCore.Measurements.DataSource

    field :unit, :string
    field :sampling_interval_seconds, :integer
    field :aggregation_type, :string
    field :is_active, :boolean, default: true
    timestamps(type: :utc_datetime_usec)

    has_many :measurements, AlonaCore.Measurements.Measurement, foreign_key: :stream_id
    has_one :current_value, AlonaCore.Measurements.CurrentValue, foreign_key: :stream_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :property_id,
      :name,
      :slug,
      :metric_id,
      :source_entity_id,
      :subject_entity_id,
      :data_source_id,
      :unit,
      :sampling_interval_seconds,
      :aggregation_type,
      :is_active
    ])
    |> validate_required([:property_id, :name, :slug, :metric_id, :unit])
    |> unique_constraint([:property_id, :slug])
  end
end
