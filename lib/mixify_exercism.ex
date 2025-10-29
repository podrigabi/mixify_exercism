defmodule MixifyExercism do
  @moduledoc """
  Converts Erlang rebar.config files from Exercism exercises to Elixir mix.exs format.

  MixifyExercism can parse rebar.config files and generate equivalent mix.exs
  configuration files, making it easier to migrate Erlang Exercism projects to
  Elixir or use Erlang projects within Mix.
  """

  alias MixifyExercism.{RebarConfig, MixGenerator}

  @doc """
  Converts a rebar.config file to mix.exs format.

  ## Parameters

    * `rebar_path` - Path to the rebar.config file
    * `opts` - Options for generation:
      * `:app_name` - Application name (default: inferred from directory)
      * `:version` - Version string (default: "0.1.0")
      * `:elixir_version` - Elixir version requirement (default: "~> 1.17")
      * `:output_path` - Where to write mix.exs (default: returns content)

  ## Examples

      iex> MixifyExercism.convert("path/to/rebar.config")
      {:ok, "defmodule MyApp.MixProject do..."}

      iex> MixifyExercism.convert("path/to/rebar.config", output_path: "mix.exs")
      {:ok, "mix.exs written successfully"}

  """
  @spec convert(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def convert(rebar_path, opts \\ []) do
    with {:ok, config} <- RebarConfig.parse(rebar_path),
         app_name <- infer_app_name(rebar_path, opts),
         opts <- Keyword.put(opts, :app_name, app_name),
         content <- MixGenerator.generate(config, opts) do
      case Keyword.get(opts, :output_path) do
        nil ->
          {:ok, content}

        output_path ->
          case File.write(output_path, content) do
            :ok -> {:ok, "mix.exs written successfully to #{output_path}"}
            {:error, reason} -> {:error, reason}
          end
      end
    end
  end

  @doc """
  Converts a rebar.config file and writes the result to a file.

  ## Examples

      iex> MixifyExercism.convert!("path/to/rebar.config", "mix.exs")
      "defmodule MyApp.MixProject do..."

  """
  @spec convert!(String.t(), String.t(), keyword()) :: String.t()
  def convert!(rebar_path, output_path, opts \\ []) do
    opts = Keyword.put(opts, :output_path, output_path)

    case convert(rebar_path, opts) do
      {:ok, result} -> result
      {:error, reason} -> raise "Failed to convert: #{inspect(reason)}"
    end
  end

  defp infer_app_name(rebar_path, opts) do
    Keyword.get_lazy(opts, :app_name, fn ->
      rebar_path
      |> Path.dirname()
      |> Path.basename()
      |> String.replace("-", "_")
      |> String.to_atom()
    end)
  end
end
