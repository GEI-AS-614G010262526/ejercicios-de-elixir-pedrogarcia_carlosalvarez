defmodule EratostenesTest do
  use ExUnit.Case
  doctest Eratostenes

  test "greets the world" do
    assert Eratostenes.hello() == :world
  end
end
