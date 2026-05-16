defmodule AlonaCore.Measurements.CurrentValue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "current_values" do
    belongs_to :stream,
               AlonaCore.Measurements.MeasurementStream,
               foreign_key: :stream_id,
               primary_key: true

    field :latest_value, :float
    field :latest_value_text, :string
    field :measured_at, :utc_datetime_usec
    field :quality, :integer
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:stream_id, :latest_value, :latest_value_text, :measured_at, :quality])
    |> validate_required([:stream_id, :measured_at])
    |> assoc_constraint(:stream)
  end
end
