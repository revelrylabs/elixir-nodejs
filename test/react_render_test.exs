defmodule ReactRender.Test do
  use ExUnit.Case
  doctest ReactRender

  setup do
    ReactRender.start_link("priv/react_render_service/index.js")
    :ok
  end

  test "Returns html" do
    {:ok, html} = ReactRender.get_html("./HelloWorld.js", %{name: "test"})
    assert html =~ "<div data-reactroot=\"\">Hello"
    assert html =~ "test</div>"
  end

  test "Returns error when no component found" do
    {:error, error} = ReactRender.get_html("./Taco.js")
    assert error.message =~ "Cannot find module"
  end

  test "stop" do
    assert ReactRender.stop() == :ok
  end
end
