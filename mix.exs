defmodule ReactRender.MixProject do
  use Mix.Project

  def project do
    [
      app: :react_render,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],

      # Docs
      name: "ReactRender",
      source_url: "https://github.com/revelrylabs/elixir_react_render",
      homepage_url: "https://github.com/revelrylabs/elixir_react_render",
      # The main page in the docs
      docs: [main: "ReactRender", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.18.1", only: :dev},
      {:excoveralls, "~> 0.8.0", only: :test}
    ]
  end

  defp description do
    """
    Renders React components as HTML
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "priv/server.js",
        "priv/client.js",
        "priv/.babelrc",
        "package.json"
      ],
      maintainers: ["Bryan Joseph", "Luke Ledet"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/revelrylabs/elixir_react_render"
      },
      build_tools: ["mix"]
    ]
  end
end
