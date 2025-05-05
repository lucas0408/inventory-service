defmodule InventoryService.Application do
  use Application

  defp poolboy_config do
    [
      name: {:local, :worker_stock},
      worker_module: InventoryService.Stock,
      size: 10,
      max_overflow: 10,
      worker_restart_strategy: :one_for_one,
      max_restart_intensity: 3,
      max_restart_period: 5
    ]
  end

  @impl true
  def start(_type, _args) do
    children = [
      InventoryService.Repo,
      {InventoryService.ProcessRegistry, []},
      {InventoryService.Database, "stocks"},
      {InventoryService.RabbitMQConfig, []},
      :poolboy.child_spec(:worker_stock, poolboy_config())
    ]

    opts = [strategy: :one_for_one, name: InventoryService.Supervisor]
    Supervisor.start_link(children, opts)
  end

end