defmodule MixifyExercism.RebarConfig do
  @moduledoc """
  Parses rebar.config files using Erlang's file:consult/1
  """

  @type config :: %{
          erl_opts: list(),
          deps: list(),
          dialyzer: keyword(),
          eunit_tests: list(),
          eunit_opts: keyword(),
          xref_warnings: boolean(),
          xref_checks: list()
        }

  @doc """
  Parses a rebar.config file and returns a map with the configuration.

  ## Examples

      iex> MixifyExercism.RebarConfig.parse("path/to/rebar.config")
      {:ok, %{erl_opts: [...], deps: [...]}}

  """
  @spec parse(String.t()) :: {:ok, config()} | {:error, term()}
  def parse(path) do
    case :file.consult(String.to_charlist(path)) do
      {:ok, terms} ->
        config = parse_terms(terms)
        {:ok, config}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_terms(terms) do
    Enum.reduce(terms, %{}, fn term, acc ->
      case term do
        {:erl_opts, opts} ->
          Map.put(acc, :erl_opts, opts)

        {:deps, deps} ->
          Map.put(acc, :deps, deps)

        {:dialyzer, opts} ->
          Map.put(acc, :dialyzer, opts)

        {:eunit_tests, tests} ->
          Map.put(acc, :eunit_tests, tests)

        {:eunit_opts, opts} ->
          Map.put(acc, :eunit_opts, opts)

        {:xref_warnings, value} ->
          Map.put(acc, :xref_warnings, value)

        {:xref_checks, checks} ->
          Map.put(acc, :xref_checks, checks)

        # Ignore other terms
        _ ->
          acc
      end
    end)
  end
end
