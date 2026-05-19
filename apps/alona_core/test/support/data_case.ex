defmodule AlonaCore.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias AlonaCore.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import AlonaCore.DataCase
    end
  end

  setup tags do
    AlonaCore.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(AlonaCore.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
