defmodule AlonaUiWeb.FinanceLive do
  use AlonaUiWeb, :live_view

  alias AlonaCore.Finance

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      AlonaCore.Broadcast.subscribe_dashboard()
    end

    socket =
      socket
      |> assign(:page_title, "Finance")
      |> assign(:active_nav, :finance)

    {:ok, reload(socket)}
  end

  defp reload(socket) do
    assign(socket,
      expenses: Finance.list_expenses(),
      categories: Finance.list_categories()
    )
  end

  @impl true
  def handle_info(:refresh_dashboard, socket) do
    {:noreply, reload(socket)}
  end

  @impl true
  def handle_event("create_expense", params, socket) do
    title = params["title"] |> to_string() |> String.trim()
    amt_raw = params["amount"] |> to_string() |> String.trim()

    if title == "" or amt_raw == "" do
      {:noreply, put_flash(socket, :error, "title & amount required")}
    else
      case Decimal.cast(amt_raw) do
        {:ok, dec} ->
          currency = currency_or_default(params["currency"])
          category_id = parse_category(params["category_id"])

          Finance.create_expense!(%{
            date: parse_date(params["date"]),
            title: title,
            amount: dec,
            currency: currency,
            vendor: empty_to_nil(params["vendor"]),
            category_id: category_id
          })

          {:noreply,
           socket
           |> put_flash(:info, "expense saved")
           |> reload()}

        :error ->
          {:noreply, put_flash(socket, :error, "amount must be a number")}
      end
    end
  end

  defp parse_date(bin) when is_binary(bin) do
    trimmed = String.trim(bin)
    if trimmed == "", do: Date.utc_today(), else: date_from_iso(trimmed)
  end

  defp parse_date(_), do: Date.utc_today()

  defp date_from_iso(trimmed) do
    case Date.from_iso8601(trimmed) do
      {:ok, d} -> d
      {:error, _} -> Date.utc_today()
    end
  end

  defp currency_or_default(bin) when is_binary(bin) do
    trimmed = bin |> String.trim() |> String.upcase()
    if trimmed == "", do: "USD", else: trimmed
  end

  defp currency_or_default(_), do: "USD"

  defp parse_category(bin) when is_binary(bin) do
    trimmed = String.trim(bin)

    if trimmed == "" do
      nil
    else
      case Integer.parse(trimmed) do
        {id, _} -> id
        :error -> nil
      end
    end
  end

  defp parse_category(_), do: nil

  defp empty_to_nil(nil), do: nil

  defp empty_to_nil(bin) when is_binary(bin) do
    trimmed = String.trim(bin)
    if trimmed == "", do: nil, else: trimmed
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="space-y-2">
      <p class="text-xs uppercase tracking-[0.28em] text-base-content/55">finance rail</p>

      <h1 class="text-3xl font-semibold tracking-tight">Expenses</h1>

      <p class="text-sm text-base-content/65">minimal ledger view + quick capture form.</p>
    </section>

    <section class="mt-8 grid gap-6 lg:grid-cols-2">
      <article class="rounded-xl border border-base-200 bg-base-100 p-5 shadow-sm">
        <p class="text-sm font-semibold">log expense</p>

        <form id="expense-form" phx-submit="create_expense" class="mt-4 space-y-3">
          <div>
            <label class="text-xs uppercase text-base-content/55" for="expense-title-input">title</label>

            <input
              id="expense-title-input"
              required
              name="title"
              type="text"
              class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
            />
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div>
              <label class="text-xs uppercase text-base-content/55" for="expense-amount-input">amount</label>

              <input
                id="expense-amount-input"
                required
                step="any"
                name="amount"
                type="number"
                class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
              />
            </div>

            <div>
              <label class="text-xs uppercase text-base-content/55" for="expense-currency-input">currency</label>

              <input
                id="expense-currency-input"
                name="currency"
                type="text"
                value="USD"
                class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
              />
            </div>
          </div>

          <div class="grid gap-3 sm:grid-cols-2">
            <div>
              <label class="text-xs uppercase text-base-content/55" for="expense-date-input">date</label>

              <input id="expense-date-input" name="date" type="date" class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm" />
            </div>

            <div>
              <label class="text-xs uppercase text-base-content/55" for="expense-category-select">category</label>

              <select
                id="expense-category-select"
                name="category_id"
                class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
              >
                <option value="">optional</option>

                <%= for c <- @categories do %>
                  <option value={c.id}>{c.name}</option>
                <% end %>
              </select>
            </div>
          </div>

          <div>
            <label class="text-xs uppercase text-base-content/55" for="expense-vendor-input">vendor</label>

            <input
              id="expense-vendor-input"
              name="vendor"
              type="text"
              class="mt-1 w-full rounded-lg border border-base-300 bg-base-200 px-3 py-2 text-sm"
            />
          </div>

          <button class="btn btn-primary btn-sm mt-2" type="submit">save</button>
        </form>
      </article>

      <div class="overflow-hidden rounded-xl border border-base-200 bg-base-100 shadow-sm">
        <table class="table table-sm">
          <thead class="border-b border-base-200 bg-base-200">
            <tr>
              <th>date</th>

              <th>title</th>

              <th class="text-right">amount</th>
            </tr>
          </thead>

          <tbody>
            <%= for e <- @expenses do %>
              <tr class="border-b border-base-200 last:border-none">
                <td class="align-top whitespace-nowrap text-xs text-base-content/60">{e.date |> to_string()}</td>

                <td class="align-top">{e.title}</td>

                <td class="align-top text-right text-sm">{Decimal.round(e.amount, 2) |> Decimal.to_string()}</td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>
    """
  end
end
