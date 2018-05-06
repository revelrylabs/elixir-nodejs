defmodule Mix.Tasks.ReactRender.Install do
  use Mix.Task

  @shortdoc "Adds React html renderer to project"

  @moduledoc """
  Adds React html renderer to project

  usage:

  mix react_render.install           install react renderer into priv folder
  mix react_render.install --path <path>    install react renderer into path
  """

  @doc false
  def run(args) do
    Mix.Task.run("app.start")
    parse_args(args)
  end

  defp parse_args(args) do
    options = OptionParser.parse(args, switches: [path: :string])

    case options do
      {[], [], []} ->
        install("priv")

      {[path: path], [], []} ->
        install(path)

      _ ->
        Mix.Shell.IO.info(help())
    end
  end

  defp install(path) do
    input = Path.join([:code.priv_dir(:react_render), "react_render_service"])
    output = Path.join(path, "react_render_service")
    Mix.Generator.create_directory(output)

    File.cp_r(input, output)

    if Mix.Shell.IO.yes?("Run npm install?") do
      Mix.Shell.IO.cmd("pushd #{output} && npm install && popd")
    end

    Mix.Shell.IO.info("Installation Complete")
  end

  defp help() do
    """
    Adds React html renderer to project

    usage:

    mix react_render.install           install react renderer into priv folder
    mix react_render.install --path <path>    install react renderer into path
    """
  end
end
