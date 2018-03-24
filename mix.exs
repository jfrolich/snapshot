defmodule Snapshot.MixProject do
  use Mix.Project

  def project do
    [
      app: :snapshot,
      version: "0.1.0",
      elixir: "~> 1.7-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Snapshots, make testing fast",
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["Jaap Frolich"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jfrolich/snapshot"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
      # env: [dir: Path.join([__DIR__, "..", "..", "test", "snapshots"])]
    ]
  end

  defp deps do
    [
      {:pre_commit, "~> 0.2.4", only: :dev}
    ]
  end
end
