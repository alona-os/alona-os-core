defmodule AlonaCore.States do
  alias AlonaCore.Repo

  alias AlonaCore.States.{
    EntityState,
    StateHistory
  }

  def upsert_entity_state!(attrs) when is_map(attrs) do
    entity_id = Map.fetch!(attrs, :entity_id)
    state_key = Map.fetch!(attrs, :state_key)

    current =
      Repo.get_by(EntityState,
        entity_id: entity_id,
        state_key: state_key
      )

    cs =
      case current do
        nil ->
          EntityState.changeset(%EntityState{}, attrs)

        row ->
          EntityState.changeset(row, attrs)
      end

    Repo.insert_or_update!(cs)
  end

  def record_state_transition!(attrs) do
    %StateHistory{}
    |> StateHistory.changeset(attrs)
    |> Repo.insert!()
  end
end
