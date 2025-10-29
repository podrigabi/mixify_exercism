defmodule MixifyExercism.Batch do
  @moduledoc """
  Batch conversion utilities for processing multiple rebar.config files.
  """

  require Logger

  @doc """
  Converts all rebar.config files found in a directory recursively.

  ## Parameters

    * `root_path` - Root directory to search for rebar.config files
    * `opts` - Options for conversion (same as MixifyExercism.convert/2)

  ## Examples

      iex> MixifyExercism.Batch.convert_all("/path/to/exercism/erlang/exercises/practice")
      {:ok, %{success: 85, failed: 0, results: [...]}}

  """
  @spec convert_all(String.t(), keyword()) ::
          {:ok, %{success: integer(), failed: integer(), results: list()}}
  def convert_all(root_path, opts \\ []) do
    rebar_configs =
      Path.wildcard(Path.join([root_path, "**", "rebar.config"]))
      |> Enum.sort()

    results =
      rebar_configs
      |> Enum.map(fn rebar_path ->
        output_path = Path.join(Path.dirname(rebar_path), "mix.exs")
        convert_opts = Keyword.put(opts, :output_path, output_path)

        case MixifyExercism.convert(rebar_path, convert_opts) do
          {:ok, _message} ->
            Logger.info("Successfully converted: #{rebar_path}")
            {:ok, rebar_path}

          {:error, reason} ->
            Logger.error("Failed to convert #{rebar_path}: #{inspect(reason)}")
            {:error, {rebar_path, reason}}
        end
      end)

    success = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    {:ok, %{success: success, failed: failed, results: results}}
  end

  @doc """
  Validates that a converted mix.exs file can be compiled.

  ## Parameters

    * `mix_path` - Path to the mix.exs file to validate

  ## Examples

      iex> MixifyExercism.Batch.validate_mix_file("/path/to/mix.exs")
      {:ok, :valid}

  """
  @spec validate_mix_file(String.t()) :: {:ok, :valid} | {:error, term()}
  def validate_mix_file(mix_path) do
    case Code.compile_file(mix_path) do
      [{module, _}] ->
        # Check if it's a valid Mix project
        if function_exported?(module, :project, 0) do
          {:ok, :valid}
        else
          {:error, :not_a_mix_project}
        end

      [] ->
        {:error, :empty_compilation}

      error ->
        {:error, error}
    end
  rescue
    e -> {:error, e}
  end

  @doc """
  Generates a report of conversion results.

  ## Parameters

    * `results` - Results from convert_all/2

  """
  @spec report(map()) :: String.t()
  def report(%{success: success, failed: failed, results: results}) do
    failed_details =
      results
      |> Enum.filter(&match?({:error, _}, &1))
      |> Enum.map(fn {:error, {path, reason}} ->
        "  - #{path}: #{inspect(reason)}"
      end)
      |> Enum.join("\n")

    """
    Conversion Report
    =================
    Total files: #{success + failed}
    Successful: #{success}
    Failed: #{failed}

    #{if failed > 0, do: "Failed conversions:\n#{failed_details}", else: "All conversions successful!"}
    """
  end
end
