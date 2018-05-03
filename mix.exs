defmodule ServerSideRender.MixProject do
  use Mix.Project

  def project do
    [
      app: :server_side_render,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ServerSideRender.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.5"},
      {:retry, "~> 0.8"},
      {:httpoison, "~> 1.1"},
      {:porcelain, "~> 2.0"},
      {:confex, "~> 3.3"}
    ]
  end
end
