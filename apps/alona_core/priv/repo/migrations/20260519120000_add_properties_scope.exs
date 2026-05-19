defmodule AlonaCore.Repo.Migrations.AddPropertiesScope do
  use Ecto.Migration

  @default_property_slug "default-site"

  def up do
    create table(:properties) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "active"
      add :metadata, :map, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:properties, [:slug])

    execute(
      """
      INSERT INTO properties (name, slug, status, metadata, inserted_at, updated_at)
      VALUES ('Default Site', '#{@default_property_slug}', 'active', '{}', NOW(), NOW())
      """
    )

    for table <- [:locations, :entities, :data_sources, :measurement_streams] do
      alter table(table) do
        add :property_id, references(:properties, on_delete: :restrict)
      end
    end

    execute("""
    UPDATE locations
    SET property_id = (SELECT id FROM properties WHERE slug = '#{@default_property_slug}')
    WHERE property_id IS NULL
    """)

    execute("""
    UPDATE entities
    SET property_id = (SELECT id FROM properties WHERE slug = '#{@default_property_slug}')
    WHERE property_id IS NULL
    """)

    execute("""
    UPDATE data_sources
    SET property_id = (SELECT id FROM properties WHERE slug = '#{@default_property_slug}')
    WHERE property_id IS NULL
    """)

    execute("""
    UPDATE measurement_streams
    SET property_id = (SELECT id FROM properties WHERE slug = '#{@default_property_slug}')
    WHERE property_id IS NULL
    """)

    alter table(:locations), do: modify(:property_id, :bigint, null: false)
    alter table(:entities), do: modify(:property_id, :bigint, null: false)
    alter table(:data_sources), do: modify(:property_id, :bigint, null: false)
    alter table(:measurement_streams), do: modify(:property_id, :bigint, null: false)

    drop unique_index(:measurement_streams, [:slug])
    drop unique_index(:entities, [:name])

    create unique_index(:measurement_streams, [:property_id, :slug])
    create unique_index(:entities, [:property_id, :name])
    create index(:measurement_streams, [:property_id])
    create index(:entities, [:property_id])
    create index(:locations, [:property_id])
    create index(:data_sources, [:property_id])
  end

  def down do
    drop unique_index(:measurement_streams, [:property_id, :slug])
    drop unique_index(:entities, [:property_id, :name])
    drop index(:measurement_streams, [:property_id])
    drop index(:entities, [:property_id])
    drop index(:locations, [:property_id])
    drop index(:data_sources, [:property_id])

    create unique_index(:measurement_streams, [:slug])
    create unique_index(:entities, [:name])

    for table <- [:locations, :entities, :data_sources, :measurement_streams] do
      alter table(table) do
        remove :property_id
      end
    end

    drop table(:properties)
  end
end
