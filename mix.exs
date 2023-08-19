defmodule Chroma.MixProject do
  use Mix.Project

  def project do
    [
      app: :chroma,
      version: "0.1.0",
      elixir: "~> 1.15",
      description: "A ChromaDB client for Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Chroma.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30.5", only: :dev, runtime: false},
      {:req, "~> 0.3.11"}
    ]
  end

  def package do
    [
      maintainers: ["Luis Ezcurdia"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/3zcurdia/chroma"}
    ]
  end
end
