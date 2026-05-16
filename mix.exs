defmodule AlonaOsCore.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: ["ecto.setup": :dev, "ecto.seed": :dev, setup: :dev]]
  end

  defp deps do
    []
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.seed": ["run apps/alona_core/priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"]
    ]
  end
end
