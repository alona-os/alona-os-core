defmodule AlonaIngest.Fixtures do
  @moduledoc false

  alias AlonaCore.Measurements.{MeasurementStream, MetricDefinition}
  alias AlonaCore.Repo
  alias AlonaCore.Topology.Property

  def insert_property!(slug) do
    case Repo.get_by(Property, slug: slug) do
      %Property{} = property ->
        property

      nil ->
        %Property{}
        |> Property.changeset(%{name: String.capitalize(slug), slug: slug, status: "active"})
        |> Repo.insert!()
    end
  end

  def insert_metric!(attrs \\ %{}) do
    defaults = %{
      name: "temperature_c_#{System.unique_integer()}",
      unit: "°C",
      value_type: "number",
      category: "test"
    }

    %MetricDefinition{}
    |> MetricDefinition.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  def insert_stream!(property, slug, metric \\ nil) do
    metric = metric || insert_metric!()

    %MeasurementStream{}
    |> MeasurementStream.changeset(%{
      property_id: property.id,
      name: slug,
      slug: slug,
      metric_id: metric.id,
      unit: "°C",
      is_active: true
    })
    |> Repo.insert!()
  end

  def telemetry_fixture(opts \\ []) do
    slug = Keyword.get(opts, :slug, "env_living_temp_c")
    property_slug = Keyword.get(opts, :property_slug, "default-site")
    property = insert_property!(property_slug)
    metric = insert_metric!(Keyword.get(opts, :metric_attrs, %{}))
    stream = insert_stream!(property, slug, metric)
    %{property: property, stream: stream, metric: metric}
  end
end
