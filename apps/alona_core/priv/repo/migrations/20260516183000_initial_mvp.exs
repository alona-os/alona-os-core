defmodule AlonaCore.Repo.Migrations.InitialMvp do
  use Ecto.Migration

  def change do
    create table(:domains) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :parent_domain_id, references(:domains, on_delete: :nilify_all)
      add :status, :string, null: false, default: "active"
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:domains, [:slug])

    create table(:locations) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :description, :text
      add :parent_location_id, references(:locations, on_delete: :nilify_all)
      timestamps(type: :utc_datetime_usec)
    end

    create table(:entities) do
      add :name, :string, null: false
      add :aliases, {:array, :string}, default: []
      add :description, :text
      add :entity_type, :string, null: false
      add :status, :string, null: false, default: "active"
      add :installed_at, :utc_datetime_usec
      add :retired_at, :utc_datetime_usec
      add :notes, :text
      add :metadata, :map, default: %{}
      add :primary_domain_id, references(:domains, on_delete: :nilify_all)
      add :location_id, references(:locations, on_delete: :nilify_all)
      add :parent_entity_id, references(:entities, on_delete: :nilify_all)
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:entities, [:name])

    create table(:entity_links) do
      add :source_entity_id, references(:entities, on_delete: :delete_all), null: false
      add :target_entity_id, references(:entities, on_delete: :delete_all), null: false
      add :relation_type, :string, null: false
      add :valid_from, :utc_datetime_usec
      add :valid_to, :utc_datetime_usec
      add :notes, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:entity_links, [:source_entity_id])
    create index(:entity_links, [:target_entity_id])

    create table(:data_sources) do
      add :name, :string, null: false
      add :source_type, :string, null: false
      add :integration_type, :string
      add :status, :string, null: false, default: "active"
      add :last_seen_at, :utc_datetime_usec
      add :metadata, :map, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create table(:metric_definitions) do
      add :name, :string, null: false
      add :unit, :string, null: false
      add :value_type, :string, null: false
      add :category, :string
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:metric_definitions, [:name])

    create table(:devices) do
      add :entity_id, references(:entities, on_delete: :nilify_all)
      add :data_source_id, references(:data_sources, on_delete: :nilify_all)
      add :device_type, :string, null: false
      add :manufacturer, :string
      add :model, :string
      add :firmware_version, :string
      add :status, :string, null: false, default: "active"
      add :last_seen_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create table(:sensors) do
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :device_id, references(:devices, on_delete: :nilify_all)
      add :sensor_type, :string, null: false
      add :status, :string, null: false, default: "active"
      add :calibration_data, :map, default: %{}
      add :installed_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:sensors, [:device_id])

    create table(:measurement_streams) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :metric_id, references(:metric_definitions, on_delete: :nothing), null: false
      add :source_entity_id, references(:entities, on_delete: :nothing)
      add :subject_entity_id, references(:entities, on_delete: :nothing)
      add :data_source_id, references(:data_sources, on_delete: :nilify_all)
      add :unit, :string, null: false
      add :sampling_interval_seconds, :integer
      add :aggregation_type, :string
      add :is_active, :boolean, default: true, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:measurement_streams, [:slug])

    create table(:measurements) do
      add :stream_id, references(:measurement_streams, on_delete: :delete_all), null: false
      add :measured_at, :utc_datetime_usec, null: false
      add :value_number, :float
      add :value_text, :string
      add :value_boolean, :boolean
      add :quality, :integer
      add :raw_payload, :map, default: %{}
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create index(:measurements, [:stream_id, :measured_at])

    create table(:current_values, primary_key: false) do
      add :stream_id, references(:measurement_streams, on_delete: :delete_all),
        primary_key: true,
        null: false

      add :latest_value, :float
      add :latest_value_text, :string
      add :measured_at, :utc_datetime_usec, null: false
      add :quality, :integer
      timestamps(type: :utc_datetime_usec)
    end

    create table(:events) do
      add :event_type, :string, null: false
      add :severity, :string
      add :title, :string, null: false
      add :description, :text
      add :occurred_at, :utc_datetime_usec, null: false
      add :source_type, :string
      add :source_id, :string
      add :actor_type, :string
      add :actor_id, :string
      add :payload, :map, default: %{}
      timestamps(type: :utc_datetime_usec)
    end

    create index(:events, [:occurred_at])

    create table(:event_links) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :relation_type, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create index(:event_links, [:event_id])

    create table(:observations) do
      add :title, :string, null: false
      add :body, :text
      add :observed_at, :utc_datetime_usec, null: false
      add :severity, :string
      add :observation_type, :string
      add :created_by, :string
      timestamps(type: :utc_datetime_usec)
    end

    create table(:observation_links, primary_key: false) do
      add :observation_id,
          references(:observations, on_delete: :delete_all),
          primary_key: true,
          null: false

      add :entity_id,
          references(:entities, on_delete: :delete_all),
          primary_key: true,
          null: false

      add :relation_type, :string, primary_key: true, null: false
    end

    create table(:tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :priority, :string, null: false, default: "medium"
      add :due_at, :utc_datetime_usec
      add :scheduled_for, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :source_type, :string
      add :source_id, :string
      add :recurrence_rule, :text
      add :estimated_duration_minutes, :integer
      timestamps(type: :utc_datetime_usec)
    end

    create index(:tasks, [:due_at])
    create index(:tasks, [:status])

    create table(:task_links) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :relation_type, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create index(:task_links, [:task_id])

    create table(:task_checklist_items) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :sort_order, :integer, null: false, default: 0
      timestamps(type: :utc_datetime_usec)
    end

    create index(:task_checklist_items, [:task_id])

    create table(:expense_categories) do
      add :name, :string, null: false
      add :parent_category_id, references(:expense_categories, on_delete: :nilify_all)
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:expense_categories, [:name])

    create table(:expenses) do
      add :date, :date, null: false
      add :title, :string, null: false
      add :description, :text
      add :amount, :decimal, null: false, precision: 12, scale: 2
      add :currency, :string, null: false
      add :vendor, :string
      add :payment_method, :string
      add :category_id, references(:expense_categories, on_delete: :nilify_all)
      add :notes, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:expenses, [:date])

    create table(:resource_types) do
      add :name, :string, null: false
      add :base_unit, :string, null: false
      add :category, :string
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:resource_types, [:name])

    create table(:resource_stores) do
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :resource_type_id, references(:resource_types, on_delete: :nothing), null: false
      add :capacity, :decimal, precision: 14, scale: 4
      add :unit, :string, null: false
      add :current_estimated_amount, :decimal, precision: 14, scale: 4
      add :min_safe_amount, :decimal, precision: 14, scale: 4
      add :max_safe_amount, :decimal, precision: 14, scale: 4
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:resource_stores, [:entity_id, :resource_type_id])

    create table(:expense_allocations) do
      add :expense_id, references(:expenses, on_delete: :delete_all), null: false
      add :entity_id, references(:entities, on_delete: :nilify_all)
      add :domain_id, references(:domains, on_delete: :nilify_all)
      add :resource_type_id, references(:resource_types, on_delete: :nilify_all)
      add :amount, :decimal, precision: 12, scale: 2
      add :percentage, :float
      add :notes, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:expense_allocations, [:expense_id])

    create table(:resource_flows) do
      add :resource_type_id, references(:resource_types, on_delete: :nothing), null: false
      add :flow_type, :string, null: false
      add :quantity, :decimal, null: false, precision: 14, scale: 4
      add :unit, :string, null: false
      add :from_entity_id, references(:entities, on_delete: :nilify_all)
      add :to_entity_id, references(:entities, on_delete: :nilify_all)
      add :related_entity_id, references(:entities, on_delete: :nilify_all)
      add :source_type, :string
      add :measured_by_stream_id, references(:measurement_streams, on_delete: :nilify_all)
      add :occurred_at, :utc_datetime_usec, null: false
      add :confidence, :float
      add :notes, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:resource_flows, [:occurred_at])

    create table(:entity_states, primary_key: false) do
      add :entity_id,
          references(:entities, on_delete: :delete_all),
          primary_key: true,
          null: false

      add :state_key, :string, primary_key: true, null: false
      add :state_value, :text, null: false
      add :updated_at_utc, :utc_datetime_usec, null: false
      add :source_event_id, references(:events, on_delete: :nilify_all)
    end

    create table(:state_histories) do
      add :entity_id, references(:entities, on_delete: :delete_all), null: false
      add :state_key, :string, null: false
      add :old_value, :text
      add :new_value, :text
      add :changed_at, :utc_datetime_usec, null: false
      add :source_type, :string
      add :source_id, :string
      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create index(:state_histories, [:entity_id])
  end
end
