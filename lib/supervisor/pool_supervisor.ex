defmodule InventoryService.PoolSupervisor do
  use Supervisor

  def start_link(db_folder, pool_size) do
    Supervisor.start_link(__MODULE__, {db_folder, pool_size})
  end

  def init(db_folder, pool_size) do
    children = for worker_id <- 1..pool_size do
      worker(
        InventoryService.DatabaseWorker, [db_folder, worker],
        id: {:database_worker, worker_id}
      )
    end 

    supervisor(children, strategy: :one_for_one)
  end
end