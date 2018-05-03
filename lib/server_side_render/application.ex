defmodule ServerSideRender.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = []

    opts = [strategy: :one_for_one, name: ServerSideRender.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
