defmodule AlonaCore.Resources.ResourceFlow do
  use Ecto.Schema
  import Ecto.Changeset

  alias AlonaCore.Measurements.MeasurementStream

  schema "resource_flows" do
    belongs_to :resource_type, AlonaCore.Resources.ResourceType
    field :flow_type, :string
    field :quantity, :decimal
    field :unit, :string
    belongs_to :from_entity, AlonaCore.Topology.Entity, foreign_key: :from_entity_id
    belongs_to :to_entity, AlonaCore.Topology.Entity, foreign_key: :to_entity_id
    belongs_to :related_entity, AlonaCore.Topology.Entity, foreign_key: :related_entity_id
    field :source_type, :string
    belongs_to :measured_by_stream, MeasurementStream, foreign_key: :measured_by_stream_id
    field :occurred_at, :utc_datetime_usec
    field :confidence, :float
    field :notes, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :resource_type_id,
      :flow_type,
      :quantity,
      :unit,
      :from_entity_id,
      :to_entity_id,
      :related_entity_id,
      :source_type,
      :measured_by_stream_id,
      :occurred_at,
      :confidence,
      :notes
    ])
    |> validate_required([:resource_type_id, :flow_type, :quantity, :unit, :occurred_at])
  end
end
