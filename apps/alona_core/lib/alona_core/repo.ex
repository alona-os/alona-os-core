defmodule AlonaCore.Repo do
  use Ecto.Repo,
    otp_app: :alona_core,
    adapter: Ecto.Adapters.Postgres
end
