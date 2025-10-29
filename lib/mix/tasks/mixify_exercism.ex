defmodule Mix.Tasks.MixifyExercism do
  @shortdoc "Converts Exercism Erlang rebar.config to mix.exs"

  @moduledoc """
  Converts an Erlang rebar.config file from Exercism exercises to Elixir mix.exs format.

  ## Usage

      mix mixify_exercism <rebar_config_path> [options]

  ## Options

    * `--output`, `-o` - Output path for mix.exs (default: prints to stdout)
    * `--app-name` - Application name (default: inferred from directory)
    * `--version` - Version string (default: "0.1.0")

  ## Examples

      # Print to stdout
      mix mixify_exercism path/to/rebar.config

      # Write to file
      mix mixify_exercism path/to/rebar.config -o mix.exs

      # Specify app name and version
      mix mixify_exercism rebar.config --app-name myapp --version 1.0.0

  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, args, _invalid} =
      OptionParser.parse(args,
        strict: [output: :string, app_name: :string, version: :string],
        aliases: [o: :output]
      )

    case args do
      [rebar_path] ->
        convert_file(rebar_path, opts)

      [] ->
        Mix.shell().error("Error: No rebar.config path provided")
        Mix.shell().info("Usage: mix mixify_exercism <rebar_config_path> [options]")
        Mix.shell().info("Run 'mix help mixify_exercism' for more information")
        exit({:shutdown, 1})

      _ ->
        Mix.shell().error("Error: Too many arguments")
        Mix.shell().info("Usage: mix mixify_exercism <rebar_config_path> [options]")
        exit({:shutdown, 1})
    end
  end

  defp convert_file(rebar_path, opts) do
    mix_opts = build_opts(opts)

    case MixifyExercism.convert(rebar_path, mix_opts) do
      {:ok, content} ->
        if opts[:output] do
          Mix.shell().info("Successfully wrote mix.exs to #{opts[:output]}")
        else
          Mix.shell().info(content)
        end

      {:error, reason} ->
        Mix.shell().error("Error: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp build_opts(opts) do
    []
    |> add_opt(:output_path, opts[:output])
    |> add_opt(:app_name, parse_app_name(opts[:app_name]))
    |> add_opt(:version, opts[:version])
  end

  defp add_opt(list, _key, nil), do: list
  defp add_opt(list, key, value), do: Keyword.put(list, key, value)

  defp parse_app_name(nil), do: nil
  defp parse_app_name(name) when is_binary(name), do: String.to_atom(name)
end
