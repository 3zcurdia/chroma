defmodule ChromaTest do
  use ExUnit.Case
  doctest Chroma

  test "greets the world" do
    assert Chroma.hello() == :world
  end
end
