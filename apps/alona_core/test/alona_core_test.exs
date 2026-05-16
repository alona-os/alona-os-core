defmodule AlonaCoreTest do
  use ExUnit.Case
  doctest AlonaCore

  test "greets the world" do
    assert AlonaCore.hello() == :world
  end
end
