defmodule AlonaUiWeb.Router do
  use AlonaUiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AlonaUiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlonaUiWeb do
    pipe_through :browser

    live_session :shell,
      on_mount: [{AlonaUiWeb.ShellAssigns, :default}],
      layout: {AlonaUiWeb.Layouts, :alona_shell} do
      live "/", CommandCenterLive

      live "/energy", EnergyLive
      live "/water", WaterLive
      live "/environment", EnvironmentLive

      live "/tasks", TasksLive
      live "/finance", FinanceLive
      live "/timeline", TimelineLive

      live "/resources", ResourcesLive
      live "/food-production", FoodProductionLive
      live "/security", SecurityLive
      live "/maintenance", MaintenanceLive
      live "/automations", AutomationsLive
      live "/protocols", ProtocolsLive
      live "/settings", SettingsLive
    end
  end

  if Application.compile_env(:alona_ui, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AlonaUiWeb.Telemetry
    end
  end
end
