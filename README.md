# MixifyExercism

Convert Erlang rebar.config files to Elixir mix.exs format.

## Overview

MixifyExercism is an Elixir tool that parses Erlang `rebar.config` files and generates equivalent `mix.exs` configuration files. This is particularly useful for:

- Migrating Erlang projects to Elixir
- Using Erlang projects within Mix build system
- Converting Exercism Erlang exercises to Elixir format

## Features

- Parses rebar.config using Erlang's `:file.consult/1`
- Converts common rebar.config options:
  - `erl_opts` → `elixirc_options` and `erlc_options`
  - `deps` → Mix dependencies with automatic dev/test deps
  - `dialyzer` → Dialyzer configuration (auto-adds dialyxir)
  - `xref_checks` → Test aliases
  - `eunit_opts` → EUnit test configuration (auto-adds mix_eunit)
- **Full EUnit Support**: Automatically configures erlc_options to support:
  - `-include_lib` directives for dependency header files
  - Erlang parse transforms (like `exercism_parse_transform`)
  - Running original Erlang EUnit tests with `mix eunit`
- Handles all rebar.config patterns found in [Exercism Erlang exercises](https://github.com/exercism/erlang/tree/main/exercises/practice)
- Provides both programmatic API and CLI interface

## Installation

Add `mixify_exercism` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mixify_exercism, "~> 0.1.0"}
  ]
end
```

## Usage

### Command Line

```bash
# Print to stdout
mix mixify_exercism path/to/rebar.config

# Write to file
mix mixify_exercism path/to/rebar.config -o mix.exs

# Specify app name and version
mix mixify_exercism rebar.config --app-name myapp --version 1.0.0
```

### Programmatic API

```elixir
# Convert and get content as string
{:ok, content} = MixifyExercism.convert("path/to/rebar.config")

# Convert and write to file
{:ok, message} = MixifyExercism.convert("path/to/rebar.config", output_path: "mix.exs")

# With custom options
MixifyExercism.convert!("rebar.config", "mix.exs",
  app_name: :myapp,
  version: "1.0.0",
  elixir_version: "~> 1.15"
)
```

## Running EUnit Tests

After converting a rebar.config with eunit configuration, you can run the original Erlang EUnit tests using Mix:

```bash
# First time or after cleaning
mix deps.compile && mix eunit

# Subsequent runs
mix eunit
```

The generated mix.exs automatically:
- Adds `mix_eunit` dependency from GitHub
- Configures `erlc_options` to find dependency header files and parse transforms
- Sets up `extra_applications` to include all dependencies
- No need to manually set `ERL_LIBS` environment variable!

## Example Conversion

Given a typical Exercism Erlang `rebar.config`:

```erlang
%% Erlang compiler options
{erl_opts, [debug_info, warnings_as_errors]}.

{deps, [{erl_exercism, "0.1.2"}]}.

{dialyzer, [
  {warnings, [underspecs, no_return]},
  {get_warnings, true},
  {plt_apps, top_level_deps},
  {base_plt_apps, [stdlib, kernel, crypto]}
]}.

{eunit_opts, [verbose]}.

{xref_checks, [undefined_function_calls, undefined_functions]}.
```

MixifyExercism generates:

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :myapp,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      erlc_paths: ["src"],
      erlc_include_path: "include",
      erlc_options: erlc_options(),
      elixirc_options: [debug_info: true, warnings_as_errors: true]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :erl_exercism]
    ]
  end

  defp deps do
    [
      {:erl_exercism, "~> 0.1.2"},
      {:mix_eunit, github: "dantswain/mix_eunit", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp erlc_options do
    # Automatically configured to support -include_lib and parse transforms
    # ...
  end

  defp dialyzer do
    [
      flags: [:underspecs, :no_return],
      plt_add_deps: :apps_direct,
      plt_core_path: "priv/plts",
      plt_add_apps: [:stdlib, :kernel, :crypto]
    ]
  end

  defp aliases do
    [
      test: ["test", "dialyzer"]
    ]
  end
end
```

## Supported rebar.config Options

| rebar.config | mix.exs | Notes |
|--------------|---------|-------|
| `erl_opts` | `elixirc_options`, `erlc_options` | Converts `debug_info`, `warnings_as_errors` |
| `deps` | `deps/0` | Supports version strings and git dependencies; auto-adds to `extra_applications` |
| `dialyzer` | `dialyzer/0` | Converts warnings, PLT configuration; auto-adds `dialyxir` dependency |
| `eunit_opts` | `erlc_options/0`, aliases | Configures EUnit support; auto-adds `mix_eunit` dependency |
| `eunit_tests` | `erlc_options/0` | Configures Erlang compiler for test support |
| `xref_checks` | `aliases/0` | Includes in test pipeline |

## Tested Against

MixifyExercism has been tested with all 85 practice exercises from the [Exercism Erlang track](https://github.com/exercism/erlang/tree/main/exercises/practice), ensuring compatibility with real-world rebar.config files.

## Related Projects

- [rebar3_elixir](https://hex.pm/packages/rebar3_elixir) - A rebar3 plugin that works from the Erlang side to generate mix.exs
- [rebar_mix](https://hex.pm/packages/rebar_mix) - Build Elixir dependencies with Mix from rebar projects

## Development

```bash
# Clone the repository
git clone https://github.com/yourusername/mixify_exercism.git
cd mixify_exercism

# Install dependencies
mix deps.get

# Compile
mix compile

# Run tests
mix test

# Generate documentation
mix docs
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See LICENSE file for details

