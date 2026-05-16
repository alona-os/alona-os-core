defmodule AlonaCore.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlonaCore.Repo,
      {Phoenix.PubSub, name: AlonaCore.PubSub}
    ]

    opts = [strategy: :one_for_one, name: AlonaCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
