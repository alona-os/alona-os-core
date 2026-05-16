defmodule AlonaUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AlonaUiWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:alona_ui, :dns_cluster_query) || :ignore},
      AlonaUiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AlonaUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AlonaUiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
