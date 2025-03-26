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
      extra_applications: [:logger, :amqp, :ssl],
      mod: {InventoryService.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 4.0"},
      {:jason, "~> 1.4"},
      {:hackney, "~> 1.18.0"},
      {:ssl_verify_fun, "~> 1.1"},
      {:certifi, "~> 2.12.0"}  # Add this line
    ]
  end
end