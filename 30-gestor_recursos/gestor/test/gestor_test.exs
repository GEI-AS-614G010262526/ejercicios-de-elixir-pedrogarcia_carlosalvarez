defmodule GestorTest do
  use ExUnit.Case
  doctest Gestor

  test "greets the world" do
    assert Gestor.hello() == :world
  end
end
