defmodule Simplificator3000Phoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :simplificator_3000_phoenix,
      version: "0.3.0",
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
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:plug, "~> 1.13.6", optional: true},
      {:phoenix, ">= 1.6.10", optional: true},
      {:simplificator_3000, github: "keenmate/simplificator_3000"}
    ]
  end
end
