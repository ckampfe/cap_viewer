defmodule CapViewer.MixProject do
  use Mix.Project

  @app :cap_viewer

  def project do
    [
      app: @app,
      version: "0.2.20",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CapViewer.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4", override: true},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.11", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_live_dashboard, "~> 0.1"},
      {:phoenix_live_view, "~> 0.12"},
      {:sqlitex, "~> 1.5"}
    ]
  end
end
