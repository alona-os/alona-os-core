defmodule AlonaCore.Events do
  import Ecto.Query
  alias AlonaCore.{Broadcast, Repo}
  alias AlonaCore.Events.Event

  def list_recent_events(limit \\ 50) when is_integer(limit) do
    from(e in Event, order_by: [desc: e.occurred_at], limit: ^limit)
    |> Repo.all()
  end

  def list_alert_events(limit \\ 5) when is_integer(limit) do
    from(e in Event,
      where: e.severity == "warning" or e.severity == "error",
      order_by: [desc: e.occurred_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def create_event!(attrs, opts \\ []) do
    link_entity_id = Keyword.get(opts, :link_entity_id)
    relation_type = Keyword.get(opts, :relation_type, "about")

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert!()
    |> maybe_link_entity!(link_entity_id, relation_type)
    |> tap(fn _ ->
      Broadcast.broadcast_dashboard()
    end)
  end

  defp maybe_link_entity!(event, nil, _), do: event

  defp maybe_link_entity!(event, entity_id, relation_type) when is_integer(entity_id) do
    %AlonaCore.Events.EventLink{}
    |> AlonaCore.Events.EventLink.changeset(%{
      event_id: event.id,
      entity_id: entity_id,
      relation_type: relation_type
    })
    |> Repo.insert!()

    event
  end

  defp maybe_link_entity!(event, _, _), do: event
end
