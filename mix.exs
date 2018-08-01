defmodule NodeJS.MixProject do
  use Mix.Project

  def project do
    [
      app: :nodejs,
      version: "0.1.0",
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
      name: "NodeJS",
      source_url: "https://github.com/revelrylabs/elixir-nodejs",
      homepage_url: "https://github.com/revelrylabs/elixir-nodejs",
      # The main page in the docs
      docs: [main: "NodeJS", extras: ["README.md"]]
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
      {:excoveralls, "~> 0.8.0", only: :test},
      {:poolboy, "~> 1.5.1"}
    ]
  end

  defp description do
    """
    Provides an Elixir API for calling Node.js functions.
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
      ],
      maintainers: ["Bryan Joseph", "Luke Ledet", "Joel Wietelmann"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/revelrylabs/elixir-nodejs"
      },
      build_tools: ["mix"]
    ]
  end
end
