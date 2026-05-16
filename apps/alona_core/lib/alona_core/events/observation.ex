defmodule AlonaCore.Events.Observation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "observations" do
    field :title, :string
    field :body, :string
    field :observed_at, :utc_datetime_usec
    field :severity, :string
    field :observation_type, :string
    field :created_by, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:title, :body, :observed_at, :severity, :observation_type, :created_by])
    |> validate_required([:title, :observed_at])
  end
end
