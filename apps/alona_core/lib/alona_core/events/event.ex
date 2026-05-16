defmodule AlonaCore.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :event_type, :string
    field :severity, :string
    field :title, :string
    field :description, :string
    field :occurred_at, :utc_datetime_usec
    field :source_type, :string
    field :source_id, :string
    field :actor_type, :string
    field :actor_id, :string
    field :payload, :map, default: %{}
    timestamps(type: :utc_datetime_usec)

    has_many :links, AlonaCore.Events.EventLink, foreign_key: :event_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :event_type,
      :severity,
      :title,
      :description,
      :occurred_at,
      :source_type,
      :source_id,
      :actor_type,
      :actor_id,
      :payload
    ])
    |> validate_required([:event_type, :title, :occurred_at])
  end
end
