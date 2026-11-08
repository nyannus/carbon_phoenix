defmodule CarbonPhoenix.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/nyannus/carbon_phoenix"

  def project do
    [
      app: :carbon_phoenix,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Phoenix LiveView function components for the Carbon Design System web components.",
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "guides/events_and_forms.md"],
      groups_for_extras: [Guides: ~r{guides/}],
      groups_for_modules: [
        "Phoenix components": [CarbonPhoenix.CoreComponents],
        "All Carbon components": [CarbonPhoenix.WebComponents],
        Icons: [CarbonPhoenix.Icons]
      ],
      source_ref: "v#{@version}",
      skip_undefined_reference_warnings_on: ["README.md"]
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv guides package.json README.md LICENSE .formatter.exs mix.exs)
    ]
  end
end
