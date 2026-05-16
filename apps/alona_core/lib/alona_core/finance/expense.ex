defmodule AlonaCore.Finance.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expenses" do
    field :date, :date
    field :title, :string
    field :description, :string
    field :amount, :decimal
    field :currency, :string
    field :vendor, :string
    field :payment_method, :string
    field :notes, :string
    belongs_to :category, AlonaCore.Finance.ExpenseCategory, foreign_key: :category_id
    timestamps(type: :utc_datetime_usec)

    has_many :allocations, AlonaCore.Finance.ExpenseAllocation
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [
      :date,
      :title,
      :description,
      :amount,
      :currency,
      :vendor,
      :payment_method,
      :notes,
      :category_id
    ])
    |> validate_required([:date, :title, :amount, :currency])
  end
end
