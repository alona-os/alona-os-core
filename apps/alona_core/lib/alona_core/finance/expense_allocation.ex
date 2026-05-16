defmodule AlonaCore.Finance.ExpenseAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expense_allocations" do
    belongs_to :expense, AlonaCore.Finance.Expense
    belongs_to :entity, AlonaCore.Topology.Entity
    belongs_to :domain, AlonaCore.Topology.Domain
    belongs_to :resource_type, AlonaCore.Resources.ResourceType
    field :amount, :decimal
    field :percentage, :float
    field :notes, :string
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:expense_id, :entity_id, :domain_id, :resource_type_id, :amount, :percentage, :notes])
    |> validate_required([:expense_id])
  end
end
