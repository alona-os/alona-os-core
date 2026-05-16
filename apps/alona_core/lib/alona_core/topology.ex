defmodule AlonaCore.Topology do
  import Ecto.Query
  alias AlonaCore.Repo
  alias AlonaCore.Topology.{Domain, Entity, Location}

  def list_domains, do: Repo.all(from(d in Domain, order_by: [asc: d.name]))

  def get_domain_by_slug!(slug), do: Repo.get_by!(Domain, slug: slug)

  def list_locations, do: Repo.all(from(l in Location, order_by: [asc: l.name]))

  def list_entities(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    from(e in Entity, order_by: e.name)
    |> preload(^preload)
    |> Repo.all()
  end

  def get_entity!(id), do: Repo.get!(Entity, id)

  def get_entity_by_name!(name), do: Repo.get_by!(Entity, name: name)
end
