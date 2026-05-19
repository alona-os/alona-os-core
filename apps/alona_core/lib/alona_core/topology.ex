defmodule AlonaCore.Topology do
  import Ecto.Query
  alias AlonaCore.Repo
  alias AlonaCore.Topology.{Domain, Entity, Location, Property}

  @default_property_slug "default-site"

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

  def get_entity_by_name!(name, opts \\ []) do
    property_id = resolve_property_id!(opts)
    Repo.get_by!(Entity, name: name, property_id: property_id)
  end

  def default_property, do: get_property_by_slug(@default_property_slug)

  def get_property_by_slug(slug) when is_binary(slug) do
    case Repo.get_by(Property, slug: slug) do
      %Property{} = property -> {:ok, property}
      nil -> {:error, :property_not_found}
    end
  end

  defp resolve_property_id!(opts) do
    slug = Keyword.get(opts, :property_slug, @default_property_slug)

    case get_property_by_slug(slug) do
      {:ok, %{id: id}} -> id
      {:error, :property_not_found} -> raise "property not found: #{slug}"
    end
  end
end
