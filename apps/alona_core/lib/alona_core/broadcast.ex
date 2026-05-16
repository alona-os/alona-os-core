defmodule AlonaCore.Broadcast do
  @moduledoc """
  thin pub/sub wrapper so alona_core does not reference Phoenix.Endpoint.
  """
  @dashboard_topic "alona:dashboard"

  def dashboard_topic, do: @dashboard_topic

  def subscribe_dashboard do
    Phoenix.PubSub.subscribe(AlonaCore.PubSub, @dashboard_topic)
  end

  def broadcast_dashboard do
    Phoenix.PubSub.broadcast(AlonaCore.PubSub, @dashboard_topic, :refresh_dashboard)
  end
end
