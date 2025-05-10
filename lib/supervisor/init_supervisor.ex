defmodule InventoryService.InitSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil)
  end

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

  def init(_) do
  
    children = [
      %{
          id: InventoryService.Database,
          start: {InventoryService.Database, :start_link, ["stocks"]},
          restart: :permanent,
          shutdown: 5000,
          type: :supervisor,
          modules: [InventoryService.DatabaseWorker]
      },
      :poolboy.child_spec(:worker_stock, poolboy_config())
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end