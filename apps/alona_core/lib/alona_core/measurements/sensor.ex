defmodule AlonaCore.Measurements.Sensor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sensors" do
    belongs_to :entity, AlonaCore.Topology.Entity
    belongs_to :device, AlonaCore.Measurements.Device
    field :sensor_type, :string
    field :status, :string, default: "active"
    field :calibration_data, :map, default: %{}
    field :installed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:entity_id, :device_id, :sensor_type, :status, :calibration_data, :installed_at])
    |> validate_required([:entity_id, :sensor_type, :status])
  end
end
