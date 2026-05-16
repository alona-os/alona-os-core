defmodule AlonaCore.Measurements.Measurement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "measurements" do
    belongs_to :stream, AlonaCore.Measurements.MeasurementStream, foreign_key: :stream_id
    field :measured_at, :utc_datetime_usec
    field :value_number, :float
    field :value_text, :string
    field :value_boolean, :boolean
    field :quality, :integer
    field :raw_payload, :map, default: %{}
    timestamps(updated_at: false, type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:stream_id, :measured_at, :value_number, :value_text, :value_boolean, :quality, :raw_payload])
    |> validate_required([:stream_id, :measured_at])
  end
end
