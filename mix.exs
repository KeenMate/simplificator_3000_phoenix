defmodule Simplificator3000Phoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :simplificator_3000_phoenix,
      version: "1.9.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      name: "Simplificator3000 Phoenix",
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def description() do
    "Make your life in Phoenix easier"
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "simplificator_3000_phoenix",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/simplificator_3000_phoenix"},
      source_url: "https://github.com/KeenMate/simplificator_3000_phoenix"
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"]
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
      {:ex_doc, "~> 0.27", runtime: false},
      {:plug, ">= 1.13.0", optional: true},
      {:phoenix, ">= 1.6.10", optional: true},
      {:decimal, ">= 2.2.0"},
      {:simplificator_3000, "<= 1.0.0"},
      {:jason, "~> 1.4.4", only: :test},
      {:tarams, "~> 1.0.0"}
    ]
  end
end
