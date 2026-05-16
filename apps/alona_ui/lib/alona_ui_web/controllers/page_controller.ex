defmodule AlonaUiWeb.PageController do
  use AlonaUiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
