defmodule InventoryService.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {InventoryService.RabbitMQConfig, []},
      Stock.Repo
    ]

    opts = [strategy: :one_for_one, name: InventoryService.Supervisor]
    Supervisor.start_link(children, opts)
  end

    @impl true
  def init(_args) do
    # Required by Supervisor behavior
    {:ok, nil}
  end
end