defmodule MixifyExercism.MixGenerator do
  @moduledoc """
  Generates mix.exs content from a parsed rebar.config
  """

  alias MixifyExercism.RebarConfig

  @doc """
  Generates a mix.exs file content from a rebar config.

  ## Options

    * `:app_name` - The application name (default: inferred from path or "myapp")
    * `:version` - The version string (default: "0.1.0")
    * `:elixir_version` - The Elixir version requirement (default: "~> 1.17")

  """
  @spec generate(RebarConfig.config(), keyword()) :: String.t()
  def generate(config, opts \\ []) do
    app_name = Keyword.get(opts, :app_name, "myapp")
    version = Keyword.get(opts, :version, "0.1.0")
    elixir_version = Keyword.get(opts, :elixir_version, "~> 1.17")

    project_opts = generate_project_opts(config)
    project_opts_str = if project_opts != "", do: ",\n      #{project_opts}", else: ""

    """
    defmodule #{String.capitalize(to_string(app_name))}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{app_name},
          version: "#{version}",
          elixir: "#{elixir_version}",
          start_permanent: Mix.env() == :prod,
          deps: deps()#{project_opts_str}
        ]
      end

      def application do
        [
          extra_applications: #{generate_extra_applications(config)}
        ]
      end

      defp deps do
        [
          #{generate_deps(config)}
        ]
      end
    #{generate_erlc_options(config)}
    #{generate_dialyzer(config[:dialyzer])}
    #{generate_aliases(config)}
    end
    """
  end

  defp generate_project_opts(config) do
    opts = []

    # Add aliases if xref_checks or eunit_opts present
    opts =
      if config[:xref_checks] || config[:eunit_opts] do
        ["aliases: aliases()" | opts]
      else
        opts
      end

    # Add dialyzer if present
    opts =
      if config[:dialyzer] do
        ["dialyzer: dialyzer()" | opts]
      else
        opts
      end

    # Add test coverage
    opts = ["test_coverage: [tool: ExCoveralls]" | opts]

    # Add erlc paths for Erlang compilation (test directory is added by mix_eunit)
    opts = ["erlc_paths: [\"src\"]" | opts]
    opts = ["erlc_include_path: \"include\"" | opts]

    # Add erlc_options if eunit is present (for finding dependency includes)
    opts =
      if config[:eunit_tests] != nil || config[:eunit_opts] != nil do
        ["erlc_options: erlc_options()" | opts]
      else
        opts
      end

    # Add elixirc_options based on erl_opts
    opts =
      if config[:erl_opts] do
        erl_opts = config[:erl_opts]

        elixirc_opts =
          []
          |> add_if(:warnings_as_errors in erl_opts, "warnings_as_errors: true")
          |> add_if(:debug_info in erl_opts, "debug_info: true")

        if elixirc_opts != [] do
          ["elixirc_options: [#{Enum.join(elixirc_opts, ", ")}]" | opts]
        else
          opts
        end
      else
        opts
      end

    if opts == [] do
      ""
    else
      Enum.join(Enum.reverse(opts), ",\n      ")
    end
  end

  defp add_if(list, condition, item) do
    if condition, do: [item | list], else: list
  end

  defp generate_deps(config) when is_map(config) do
    deps = config[:deps] || []

    # Convert rebar deps to Mix format
    mix_deps = Enum.map(deps, &format_dep/1)

    # Add dev/test dependencies
    dev_deps = []

    # Add dialyxir if dialyzer config is present
    dev_deps =
      if config[:dialyzer] do
        ["{:dialyxir, \"~> 1.4\", only: [:dev, :test], runtime: false}" | dev_deps]
      else
        dev_deps
      end

    # Add mix_eunit if eunit tests/opts are present
    dev_deps =
      if config[:eunit_tests] != nil || config[:eunit_opts] != nil do
        ["{:mix_eunit, github: \"dantswain/mix_eunit\", only: [:dev, :test], runtime: false}" | dev_deps]
      else
        dev_deps
      end

    all_deps = mix_deps ++ dev_deps

    if all_deps == [] do
      "# No dependencies"
    else
      Enum.join(all_deps, ",\n          ")
    end
  end

  defp format_dep({name, version}) when is_binary(version) do
    "{:#{name}, \"~> #{version}\"}"
  end

  defp format_dep({name, version}) when is_list(version) do
    # Handle char list version
    "{:#{name}, \"~> #{List.to_string(version)}\"}"
  end

  defp format_dep({name, opts}) when is_list(opts) and is_tuple(hd(opts)) do
    # Handle dependency with options like git, tag, etc.
    opts_str =
      opts
      |> Enum.map(fn
        {:git, url} -> "git: \"#{url}\""
        {:tag, tag} -> "tag: \"#{tag}\""
        {:branch, branch} -> "branch: \"#{branch}\""
        {:ref, ref} -> "ref: \"#{ref}\""
        other -> inspect(other)
      end)
      |> Enum.join(", ")

    "{:#{name}, #{opts_str}}"
  end

  defp format_dep(name) when is_atom(name) do
    "{:#{name}, \">= 0.0.0\"}"
  end

  defp format_dep(other) do
    "# Unsupported dep format: #{inspect(other)}"
  end

  defp generate_extra_applications(config) do
    # Extract dependency names from rebar deps and add to extra_applications
    # This ensures -include_lib can find dependency header files
    base_apps = [:logger]

    dep_apps =
      case config[:deps] do
        nil -> []
        deps when is_list(deps) ->
          deps
          |> Enum.map(fn
            {name, _version} when is_atom(name) -> name
            {name, _opts} when is_atom(name) -> name
            name when is_atom(name) -> name
            _ -> nil
          end)
          |> Enum.reject(&is_nil/1)
        _ -> []
      end

    all_apps = base_apps ++ dep_apps
    formatted_apps = Enum.map(all_apps, &":#{&1}") |> Enum.join(", ")
    "[#{formatted_apps}]"
  end

  defp generate_erlc_options(config) do
    # Generate erlc_options function if eunit is present
    if config[:eunit_tests] != nil || config[:eunit_opts] != nil do
      """

        defp erlc_options do
          # Base include path
          base_opts = [{:i, ~c"include"}]

          # Find dependency lib paths - check multiple possible locations
          # (mix_eunit uses custom build path but deps might be in dev)
          build_lib_paths = [
            Path.join(Mix.Project.build_path(), "lib"),
            "_build/dev/lib",
            "_build/test/lib"
          ]
          |> Enum.uniq()
          |> Enum.filter(&File.dir?/1)

          # For -include_lib("app/include/file.hrl") to work via include path,
          # add all found lib paths to the include path
          dep_lib_opts = Enum.flat_map(build_lib_paths, fn path ->
            # Only add if path exists and has dependencies
            if File.dir?(path) && Path.wildcard(Path.join(path, "*")) != [] do
              # Ensure ebin directories are on code path for parse transforms
              Path.wildcard(Path.join(path, "*/ebin"))
              |> Enum.each(&Code.prepend_path/1)

              [{:i, String.to_charlist(path)}]
            else
              []
            end
          end)

          base_opts ++ dep_lib_opts
        end
      """
    else
      ""
    end
  end

  defp generate_dialyzer(nil), do: ""

  defp generate_dialyzer(dialyzer_opts) do
    opts =
      dialyzer_opts
      |> Enum.map(fn
        {:warnings, warnings} ->
          warning_list = Enum.map(warnings, &":#{&1}") |> Enum.join(", ")
          "flags: [#{warning_list}]"

        {:plt_apps, :top_level_deps} ->
          "plt_add_deps: :apps_direct"

        {:plt_apps, :all_deps} ->
          "plt_add_deps: :apps_transitive"

        {:base_plt_apps, apps} ->
          app_list = Enum.map(apps, &":#{&1}") |> Enum.join(", ")
          "plt_core_path: \"priv/plts\",\n            plt_add_apps: [#{app_list}]"

        _ ->
          nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join(",\n            ")

    if opts != "" do
      """

        defp dialyzer do
          [
            #{opts}
          ]
        end
      """
    else
      ""
    end
  end

  defp generate_aliases(config) do
    # Generate test alias that includes xref checks if configured
    if config[:xref_checks] || config[:eunit_opts] do
      """

        defp aliases do
          [
            test: ["test", "dialyzer"]
          ]
        end
      """
    else
      ""
    end
  end
end
