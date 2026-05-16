defmodule AlonaCore.Resources do
  import Ecto.Query
  alias AlonaCore.Repo
  alias AlonaCore.Resources.{ResourceFlow, ResourceStore, ResourceType}

  def list_resource_types do
    Repo.all(from(rt in ResourceType, order_by: rt.name))
  end

  def list_stores(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(rs in ResourceStore, order_by: rs.id)
    |> preload(^preload)
    |> Repo.all()
  end

  def list_recent_flows(limit \\ 20) when is_integer(limit) do
    from(f in ResourceFlow, order_by: [desc: f.occurred_at], limit: ^limit)
    |> Repo.all()
  end
end
