defmodule InventoryService.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InventoryService.Repo,
      {InventoryService.Database, "stocks"},
      {InventoryService.Cache, []},
      {InventoryService.RabbitMQConfig, []}
    ]

    opts = [strategy: :one_for_one, name: InventoryService.Supervisor]
    Supervisor.start_link(children, opts)
  end

end