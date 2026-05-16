defmodule AlonaUiWeb.ErrorJSONTest do
  use AlonaUiWeb.ConnCase, async: true

  test "renders 404" do
    assert AlonaUiWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert AlonaUiWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
