defmodule AlonaCore.Finance do
  import Ecto.Query
  alias AlonaCore.{Repo}
  alias AlonaCore.Events
  alias AlonaCore.Finance.{Expense, ExpenseAllocation, ExpenseCategory}

  def list_expenses do
    Repo.all(from(e in Expense, order_by: [desc: e.date, desc: e.id]))
  end

  def list_categories do
    Repo.all(from(c in ExpenseCategory, order_by: c.name))
  end

  def create_expense!(attrs, allocation_attrs \\ nil) when is_map(attrs) do
    Repo.transaction(fn ->
      expense =
        %Expense{}
        |> Expense.changeset(attrs)
        |> Repo.insert!()

      maybe_insert_allocation!(expense, allocation_attrs)

      Events.create_event!(%{
        event_type: "expense",
        severity: "info",
        title: "Expense logged",
        description:
          "#{expense.title} — #{money_label(expense.amount)} #{expense.currency}",
        occurred_at: DateTime.utc_now(:microsecond),
        source_type: "expense",
        source_id: to_string(expense.id),
        actor_type: "user",
        actor_id: nil,
        payload: %{expense_id: expense.id}
      })

      expense
    end)
    |> unwrap_tx!()
  end

  defp money_label(%Decimal{} = d), do: Decimal.to_string(d)
  defp money_label(other), do: to_string(other)

  defp maybe_insert_allocation!(_expense, nil), do: :ok

  defp maybe_insert_allocation!(expense, alloc) when is_map(alloc) do
    alloc
    |> Map.put(:expense_id, expense.id)
    |> then(fn merged ->
      %ExpenseAllocation{}
      |> ExpenseAllocation.changeset(merged)
      |> Repo.insert!()
    end)
  end

  defp maybe_insert_allocation!(_expense, _), do: :ok

  defp unwrap_tx!({:ok, result}), do: result

  defp unwrap_tx!({:error, failure}) do
    raise(RuntimeError, message: "transaction failed: #{inspect(failure)}")
  end
end
