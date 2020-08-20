defmodule Dwolla.Mixfile do
  use Mix.Project

  @description """
    An Elixir Library for Dwolla
  """

  def project do
    [
      app: :dwolla,
      version: "1.1.0",
      description: @description,
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/wfgilman/dwolla-elixir",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 1.5"},
      {:poison, "~> 4.0"},
      {:recase, "~> 0.6"},
      {:bypass, "~> 1.0", only: [:test]},
      {:credo, "~> 1.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.13", only: [:test]},
      {:ex_doc, "~> 0.22", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      name: :dwolla_elixir,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["MIT"],
      maintainers: ["Will Gilman"],
      links: %{"Github" => "https://github.com/wfgilman/dwolla-elixir"}
    ]
  end

  defp docs do
    [
      extras: ["parameters.md"]
    ]
  end
end
