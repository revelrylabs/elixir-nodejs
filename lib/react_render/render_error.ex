defmodule ReactRender.RenderError do
  @moduledoc """
  Error when unable to render given component
  """

  defexception message: nil, stack: nil
end
