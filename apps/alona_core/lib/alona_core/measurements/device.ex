defmodule AlonaCore.Measurements.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    belongs_to :entity, AlonaCore.Topology.Entity
    belongs_to :data_source, AlonaCore.Measurements.DataSource
    field :device_type, :string
    field :manufacturer, :string
    field :model, :string
    field :firmware_version, :string
    field :status, :string, default: "active"
    field :last_seen_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)

    has_many :sensors, AlonaCore.Measurements.Sensor
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :entity_id,
      :data_source_id,
      :device_type,
      :manufacturer,
      :model,
      :firmware_version,
      :status,
      :last_seen_at
    ])
    |> validate_required([:device_type, :status])
  end
end
