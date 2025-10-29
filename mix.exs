defmodule MixifyExercism.MixProject do
  use Mix.Project

  def project do
    [
      app: :mixify_exercism,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Convert Erlang rebar.config files from Exercism exercises to Elixir mix.exs format",
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "mixify_exercism",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/yourusername/mixify_exercism"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
