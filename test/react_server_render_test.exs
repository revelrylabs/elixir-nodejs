defmodule ReactServerRenderTest do
  use ExUnit.Case
  doctest ReactServerRender

  test "greets the world" do
    assert ReactServerRender.hello() == :world
  end
end
