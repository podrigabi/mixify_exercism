#!/usr/bin/env elixir

# Example script for batch converting Exercism Erlang exercises
# Usage: elixir examples/batch_convert.exs <path-to-exercism-erlang>

defmodule BatchConvertExample do
  @doc """
  Demonstrates batch conversion of Exercism Erlang exercises.
  """
  def run(args) do
    case args do
      [exercises_path] ->
        convert_exercises(exercises_path)

      _ ->
        IO.puts("Usage: elixir batch_convert.exs <path-to-exercism-erlang-exercises>")
        IO.puts("Example: elixir batch_convert.exs ~/projects/erlang/exercises/practice")
        System.halt(1)
    end
  end

  defp convert_exercises(exercises_path) do
    IO.puts("Converting Exercism Erlang exercises from: #{exercises_path}\n")

    # Find all rebar.config files
    rebar_configs =
      Path.wildcard(Path.join([exercises_path, "**", "rebar.config"]))
      |> Enum.sort()

    total = length(rebar_configs)
    IO.puts("Found #{total} rebar.config files\n")

    # Convert each one
    results =
      rebar_configs
      |> Enum.with_index(1)
      |> Enum.map(fn {rebar_path, index} ->
        exercise_name = rebar_path |> Path.dirname() |> Path.basename()
        IO.write("[#{index}/#{total}] Converting #{exercise_name}... ")

        output_path = Path.join(Path.dirname(rebar_path), "mix.exs")

        case MixifyExercism.convert(rebar_path, output_path: output_path) do
          {:ok, _message} ->
            IO.puts("✓")
            {:ok, exercise_name}

          {:error, reason} ->
            IO.puts("✗")
            IO.puts("  Error: #{inspect(reason)}")
            {:error, {exercise_name, reason}}
        end
      end)

    # Print summary
    success = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("Conversion Summary")
    IO.puts(String.duplicate("=", 50))
    IO.puts("Total: #{total}")
    IO.puts("Success: #{success}")
    IO.puts("Failed: #{failed}")

    if failed > 0 do
      IO.puts("\nFailed exercises:")

      results
      |> Enum.filter(&match?({:error, _}, &1))
      |> Enum.each(fn {:error, {name, reason}} ->
        IO.puts("  - #{name}: #{inspect(reason)}")
      end)
    end

    IO.puts("\n✓ Batch conversion complete!")
  end
end

# Run the example
BatchConvertExample.run(System.argv())
