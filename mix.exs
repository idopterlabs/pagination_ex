defmodule PaginationEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/idopterlabs/pagination_ex"

  def project do
    [
      app: :pagination_ex,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "PaginationEx",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7"},
      {:ecto_sql, "~> 3.12"},
      {:ecto, "~> 3.12"},
      {:ex_doc, "~> 0.37.1", only: :dev, runtime: false},
      {:gettext, "~> 0.26.2"},
      {:jason, "~> 1.4"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:postgrex, "~> 0.20.0"},
      {:tailwind, "~> 0.2.4"}
    ]
  end

  defp description do
    """
    A flexible pagination library for Elixir and Phoenix applications.
    """
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv LICENSE.md mix.exs README.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: @version,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
