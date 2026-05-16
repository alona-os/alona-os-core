defmodule AlonaCore.Seeds do
  @moduledoc false

  alias AlonaCore.Repo

  alias AlonaCore.Topology.{Domain, Entity, Location}

  alias AlonaCore.Measurements.{CurrentValue, DataSource, Measurement, MeasurementStream, MetricDefinition}

  alias AlonaCore.Tasks.Task
  alias AlonaCore.Finance.{Expense, ExpenseCategory}
  alias AlonaCore.Events.Event

  def run do
    {:ok, _} =
      Repo.transaction(fn ->
        domains = seed_domains()
        locations = seed_locations()
        entities = seed_entities(domains, locations)

        {_source, metric_ids} = seed_metrics_and_source()

        {_streams, slug_to_id} = seed_streams(metric_ids, entities)

        seed_measurements_and_current(slug_to_id)
        seed_tasks()
        seed_categories_and_expenses()
        seed_events()

        :ok
      end)
  end

  defp seed_domains do
    [{"Energy", "energy"}, {"Water", "water"}, {"Environment", "environment"}, {"Resources", "resources"}]
    |> Enum.map(fn {name, slug} ->
      %Domain{}
      |> Domain.changeset(%{name: name, slug: slug, status: "active"})
      |> Repo.insert!()
    end)
    |> then(fn domains ->
      %{
        energy: Enum.find(domains, &(&1.slug == "energy")),
        water: Enum.find(domains, &(&1.slug == "water")),
        environment: Enum.find(domains, &(&1.slug == "environment")),
        resources: Enum.find(domains, &(&1.slug == "resources"))
      }
    end)
  end

  defp seed_locations do
    house =
      %Location{}
      |> Location.changeset(%{name: "House", type: "building"})
      |> Repo.insert!()

    %{
      house: house,
      living_room:
        insert_location!("Living Room", "room", house.id),
      bedroom:
        insert_location!("Bedroom", "room", house.id),
      bathroom:
        insert_location!("Bathroom", "room", house.id),
      well:
        %Location{}
        |> Location.changeset(%{name: "Well Area", type: "area"})
        |> Repo.insert!()
    }
  end

  defp insert_location!(name, type, parent_id) do
    %Location{}
    |> Location.changeset(%{name: name, type: type, parent_location_id: parent_id})
    |> Repo.insert!()
  end

  defp seed_entities(domains, locations) do
    %{
      battery:
        insert_entity!(%{name: "Battery Bank"},
          entity_type: "asset",
          primary_domain_id: domains.energy.id,
          location_id: locations.house.id
        ),
      pv:
        insert_entity!(%{name: "PV Array"},
          entity_type: "asset",
          primary_domain_id: domains.energy.id,
          location_id: locations.house.id
        ),
      water_tank:
        insert_entity!(%{name: "Water Tank"},
          entity_type: "asset",
          primary_domain_id: domains.water.id,
          location_id: locations.house.id
        ),
      well:
        insert_entity!(%{name: "Well"},
          entity_type: "asset",
          primary_domain_id: domains.water.id,
          location_id: locations.well.id
        ),
      house_load:
        insert_entity!(%{name: "House Load"},
          entity_type: "resource_system",
          primary_domain_id: domains.energy.id,
          location_id: locations.house.id
        ),
      living_room:
        insert_entity!(
          %{
            name: "Living Room Climate",
            description: "living space comfort readings",
            aliases: ["living", "living room"]
          },
          entity_type: "sensor",
          primary_domain_id: domains.environment.id,
          location_id: locations.living_room.id
        ),
      bedroom:
        insert_entity!(
          %{name: "Bedroom Climate", aliases: ["bedroom"]},
          entity_type: "sensor",
          primary_domain_id: domains.environment.id,
          location_id: locations.bedroom.id
        ),
      bathroom:
        insert_entity!(
          %{name: "Bathroom Climate", aliases: ["bathroom"]},
          entity_type: "sensor",
          primary_domain_id: domains.environment.id,
          location_id: locations.bathroom.id
        ),
      food:
        insert_entity!(
          %{name: "Garden", description: "placeholder crop area"},
          entity_type: "area",
          primary_domain_id: domains.resources.id,
          location_id: locations.house.id
        )
    }
  end

  defp insert_entity!(base_attrs, extra_kw) when is_map(base_attrs) and is_list(extra_kw) do
    %Entity{}
    |> Entity.changeset(Map.merge(base_attrs, Enum.into(extra_kw, %{})))
    |> Repo.insert!()
  end

  defp seed_metrics_and_source do
    source =
      %DataSource{}
      |> DataSource.changeset(%{
        name: "seed-local",
        source_type: "simulated",
        integration_type: "seed",
        status: "active"
      })
      |> Repo.insert!()

    inserted =
      [
        %{name: "battery_state_of_charge", unit: "%"},
        %{name: "power_kw", unit: "kW"},
        %{name: "tank_percent", unit: "%"},
        %{name: "volume_liters", unit: "L"},
        %{name: "temperature_c", unit: "°C"},
        %{name: "relative_humidity", unit: "%"},
        %{name: "text_status", unit: "-"}
      ]
      |> Enum.map(fn attrs ->
        value_type =
          if attrs.name == "text_status" do
            "string"
          else
            "number"
          end

        %MetricDefinition{}
        |> MetricDefinition.changeset(
          Map.merge(attrs, %{value_type: value_type, category: "seed"})
        )
        |> Repo.insert!()
      end)

    metrics = fn name ->
      Enum.find(inserted, &(&1.name == name)).id
    end

    {source,
     %{
       soc: metrics.("battery_state_of_charge"),
       kw: metrics.("power_kw"),
       tank_pct: metrics.("tank_percent"),
       liters: metrics.("volume_liters"),
       temp: metrics.("temperature_c"),
       rh: metrics.("relative_humidity"),
       text: metrics.("text_status")
     }}
  end

  defp seed_streams(metric_ids, entities) do
    subject = &%{subject_entity_id: &1.id}

    defs = [
      {"Battery SOC", "energy_battery_soc", metric_ids.soc, "%",
       subject.(entities.battery)},
      {"PV Production", "energy_pv_kw", metric_ids.kw, "kW", subject.(entities.pv)},
      {"House Load", "energy_house_load_kw", metric_ids.kw, "kW",
       subject.(entities.house_load)},
      {"Battery Flow", "energy_battery_flow_kw", metric_ids.kw, "kW",
       subject.(entities.battery)},
      {"Tank Level Percent", "water_tank_percent", metric_ids.tank_pct, "%",
       subject.(entities.water_tank)},
      {"Tank Liters Estimated", "water_tank_liters", metric_ids.liters, "L",
       subject.(entities.water_tank)},
      {"Pump Status", "water_pump_status", metric_ids.text, "-", subject.(entities.well)},
      {"Well Status", "water_well_status", metric_ids.text, "-", subject.(entities.well)},
      {"Daily Water Estimate", "water_daily_liters_estimate", metric_ids.liters, "L",
       subject.(entities.water_tank)},
      {"Generator Status", "energy_generator_status", metric_ids.text, "-",
       subject.(entities.pv)},
      {"Living Room Temperature", "env_living_temp_c", metric_ids.temp, "°C",
       subject.(entities.living_room)},
      {"Living Room Humidity", "env_living_rh", metric_ids.rh, "%",
       subject.(entities.living_room)},
      {"Bedroom Temperature", "env_bedroom_temp_c", metric_ids.temp, "°C",
       subject.(entities.bedroom)},
      {"Bedroom Humidity", "env_bedroom_rh", metric_ids.rh, "%",
       subject.(entities.bedroom)},
      {"Bathroom Temperature", "env_bathroom_temp_c", metric_ids.temp, "°C",
       subject.(entities.bathroom)},
      {"Bathroom Humidity", "env_bathroom_rh", metric_ids.rh, "%",
       subject.(entities.bathroom)}
    ]

    streams =
      Enum.map(defs, fn {name, slug, metric_id, unit, extra} ->
        %MeasurementStream{}
        |> MeasurementStream.changeset(
          Map.merge(extra, %{
            name: name,
            slug: slug,
            metric_id: metric_id,
            unit: unit,
            is_active: true
          })
        )
        |> Repo.insert!()
      end)

    slug_map = Map.new(streams, fn s -> {s.slug, s.id} end)

    {streams, slug_map}
  end

  defp seed_measurements_and_current(slug_to_id) do
    now = DateTime.utc_now(:microsecond)

    rows = [
      {"energy_battery_soc", %{value_number: 78.0}},
      {"energy_pv_kw", %{value_number: 2.4}},
      {"energy_house_load_kw", %{value_number: 1.2}},
      {"energy_battery_flow_kw", %{value_number: 1.2}},
      {"water_tank_percent", %{value_number: 65.0}},
      {"water_tank_liters", %{value_number: 3250.0}},
      {"water_pump_status", %{value_text: "idle"}},
      {"water_well_status", %{value_text: "online"}},
      {"water_daily_liters_estimate", %{value_number: 180.0}},
      {"energy_generator_status", %{value_text: "standby"}},
      {"env_living_temp_c", %{value_number: 21.5}},
      {"env_living_rh", %{value_number: 45.0}},
      {"env_bedroom_temp_c", %{value_number: 19.8}},
      {"env_bedroom_rh", %{value_number: 52.0}},
      {"env_bathroom_temp_c", %{value_number: 23.2}},
      {"env_bathroom_rh", %{value_number: 68.0}}
    ]

    Enum.each(rows, fn {slug, payload} ->
      stream_id = Map.fetch!(slug_to_id, slug)

      attrs = Map.merge(payload, %{stream_id: stream_id, measured_at: now})

      %Measurement{}
      |> Measurement.changeset(attrs)
      |> Repo.insert!()

      upsert_current_value!(
        stream_id,
        Map.fetch!(attrs, :measured_at),
        Map.get(attrs, :value_number),
        Map.get(attrs, :value_text)
      )
    end)
  end

  defp upsert_current_value!(stream_id, measured_at, number, text) do
    current =
      case Repo.get_by(CurrentValue, stream_id: stream_id) do
        nil -> struct(CurrentValue, stream_id: stream_id)
        row -> row
      end

    current
    |> CurrentValue.changeset(%{
      stream_id: stream_id,
      measured_at: measured_at,
      latest_value: number,
      latest_value_text: text,
      quality: 100
    })
    |> Repo.insert_or_update!()
  end

  defp seed_tasks do
    today = utc_midnight(Date.utc_today())

    %Task{}
    |> Task.changeset(%{
      title: "Replace water filter",
      description: "Monthly water filter cartridge swap",
      status: "pending",
      priority: "high",
      due_at: today,
      source_type: "protocol"
    })
    |> Repo.insert!()

    %Task{}
    |> Task.changeset(%{
      title: "Check PV wiring",
      status: "overdue",
      priority: "high",
      due_at: DateTime.add(today, -3 * 24 * 60 * 60, :second),
      source_type: "maintenance"
    })
    |> Repo.insert!()

    %Task{}
    |> Task.changeset(%{
      title: "Prune greenhouse tomatoes",
      status: "in_progress",
      priority: "low",
      due_at: DateTime.add(today, 2 * 24 * 60 * 60, :second),
      source_type: "manual"
    })
    |> Repo.insert!()

    :ok
  end

  defp utc_midnight(date) do
    DateTime.new!(date, ~T[00:00:00.000000], "Etc/UTC")
  end

  defp seed_categories_and_expenses do
    supplies =
      %ExpenseCategory{}
      |> ExpenseCategory.changeset(%{name: "Supplies"})
      |> Repo.insert!()

    %Expense{}
    |> Expense.changeset(%{
      date: Date.utc_today(),
      title: "Garden seeds",
      amount: Decimal.new("24.50"),
      currency: "USD",
      category_id: supplies.id,
      vendor: "local store"
    })
    |> Repo.insert!()

    :ok
  end

  defp seed_events do
    now = DateTime.utc_now(:microsecond)

    %Event{}
    |> Event.changeset(%{
      event_type: "threshold",
      severity: "warning",
      title: "Water tank below 70%",
      description: "House tank crossed the comfort threshold",
      occurred_at: DateTime.add(now, -30 * 60, :second)
    })
    |> Repo.insert!()

    %Event{}
    |> Event.changeset(%{
      event_type: "measurement",
      severity: "info",
      title: "Battery SOC updated",
      description: "Battery climbed to healthy range",
      occurred_at: DateTime.add(now, -5 * 60, :second)
    })
    |> Repo.insert!()

    :ok
  end
end

AlonaCore.Seeds.run()
