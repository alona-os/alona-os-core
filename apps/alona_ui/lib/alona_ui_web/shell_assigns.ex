defmodule AlonaUiWeb.ShellAssigns do
  @moduledoc """
  Shared assigns for `alona_shell` (e.g. header alerts) on every `live_session :shell` mount.
  """
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    alerts = AlonaCore.Events.list_alert_events(15)
    {:cont, assign(socket, :header_alerts, alerts)}
  end
end
