defmodule Mix.Tasks.Elvis do
  @moduledoc """
  Run Elvis Erlang linter on your project.

  Elvis is an Erlang style reviewer that helps maintain code quality and consistency.

  ## Usage

      mix elvis           # Run elvis with default configuration
      mix elvis rock      # Run elvis (explicit rock command)

  ## Configuration

  Elvis requires an `elvis.config` file in your project root. If this file is not found,
  the task will fail with an error message.

  See https://github.com/inaka/elvis_core for elvis.config examples.

  ## Dependencies

  This task requires the `elvis_core` package to be installed:

      {:elvis_core, "~> 4.1", only: [:dev, :test], runtime: false}

  If you used `mixify_exercism` to convert your rebar.config with an elvis.config present,
  this dependency will be added automatically.
  """

  use Mix.Task

  @shortdoc "Run Elvis Erlang linter"

  @impl Mix.Task
  def run(args) do
    # Ensure elvis_core application is loaded
    Mix.Task.run("app.start")

    # Check if elvis.config exists
    unless File.exists?("elvis.config") do
      Mix.shell().error("No elvis.config file found in the current directory")
      Mix.shell().info("Elvis requires an elvis.config file to run.")
      Mix.shell().info(
        "See https://github.com/inaka/elvis_core for configuration documentation."
      )

      exit({:shutdown, 1})
    end

    # Parse command - default to 'rock' if no args or if 'rock' is specified
    command =
      case args do
        [] -> :rock
        ["rock"] -> :rock
        [other] -> String.to_atom(other)
        _ -> :rock
      end

    Mix.shell().info("Running Elvis linter...")

    # Run elvis_core
    result =
      case command do
        :rock ->
          # Load elvis.config
          elvis_config = load_elvis_config()
          :elvis_core.rock(elvis_config)

        other ->
          Mix.shell().error("Unknown Elvis command: #{other}")
          Mix.shell().info("Available commands: rock")
          exit({:shutdown, 1})
      end

    # Handle result
    case result do
      :ok ->
        Mix.shell().info("Elvis found no problems! 🎸")
        :ok

      {:fail, results} ->
        Mix.shell().error("Elvis found style violations:")
        format_results(results)
        exit({:shutdown, 1})
    end
  end

  defp load_elvis_config do
    case :file.consult(~c"elvis.config") do
      {:ok, config} ->
        config

      {:error, reason} ->
        Mix.shell().error("Failed to read elvis.config: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp format_results(results) when is_list(results) do
    Enum.each(results, fn result ->
      format_result(result)
    end)
  end

  defp format_results(_), do: :ok

  defp format_result(%{file: file, rules: rules}) when is_list(rules) do
    IO.puts("\n#{file}:")

    Enum.each(rules, fn rule ->
      format_rule_violation(rule)
    end)
  end

  defp format_result(_), do: :ok

  defp format_rule_violation(%{line_num: line, message: message}) do
    IO.puts("  Line #{line}: #{message}")
  end

  defp format_rule_violation(%{message: message}) do
    IO.puts("  #{message}")
  end

  defp format_rule_violation(_), do: :ok
end
