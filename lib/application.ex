defmodule InventoryService.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {InventoryService.ProcessRegistry, []},
      InventoryService.Repo,
      {InventoryService.InitSupervisor, []}

    ]

    opts = [strategy: :rest_for_one, name: InventoryService.Supervisor]
    Supervisor.start_link(children, opts)
  end

end