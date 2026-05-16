defmodule AlonaCore.Finance.ExpenseCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "expense_categories" do
    field :name, :string
    belongs_to :parent_category, __MODULE__, foreign_key: :parent_category_id
    timestamps(type: :utc_datetime_usec)

    has_many :children, __MODULE__, foreign_key: :parent_category_id
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:name, :parent_category_id])
    |> validate_required([:name])
    |> foreign_key_constraint(:parent_category_id)
  end
end
