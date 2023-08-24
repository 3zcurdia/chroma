defmodule Chroma.MixProject do
  use Mix.Project

  def project do
    [
      app: :chroma,
      version: "0.1.2",
      elixir: "~> 1.15",
      description: "A ChromaDB client for Elixir",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "README",
        extras: ["README.md", "LICENSE"]
      ]
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
      {:req, "~> 0.3.11"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.30.5", only: :dev, runtime: false},
      {:mock, "~> 0.3.8", only: :test}
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
