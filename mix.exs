defmodule InventoryService.MixProject do
  use Mix.Project

  def project do
    [
      app: :inventory_service,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
    end

  def application do
    [
      extra_applications: [:logger, :amqp, :postgrex, :ecto, :ecto_sql],
      mod: {InventoryService.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 4.0"},
      {:jason, "~> 1.4"},
      {:hackney, "~> 1.18.0"},
      {:certifi, "~> 2.12.0"},
      {:ecto, "~> 3.12.5"},
      {:postgrex, "~> 0.17"},
      {:poolboy, "~> 1.5.1"},
      {:ecto_sql, "~> 3.10"}
    ]
  end
end