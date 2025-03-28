defmodule InventoryService.Database do
    use Genserver

    def start do
        GenServer.start(__MODULE__, nil, name: __MODULE__)
    end

    def get(market_id, product_id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get(product_id)
    end

    def create(market_id, product) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.create(product)
    end

    
    def get_all(market_id, worker_pid) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get_all()
    end

    def update(worker_pid, update_product, id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.update(update_product, id)
    end

    def delete(worker_pid, id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.delete(id)
    end

    defp chose_worker(mekrt_id) do
        GenServer.call(__MODULE__, {:chose_worker, market_id})
    end

    @impl GenServer
    def init(table_name) do
        {:ok, gen_workers()}
    end

    @impl GenServer
    def handle_call({:chose_worker, market_id}, workers) do
        index = :erlang.phash2(market_id, 3)
        {:reply, Map.get(workers, index), workers}
    end


    defp gen_workers do
        for index <- 1..3, into: %{} do
            {:ok, pid} = InventoryService.DatabaseWorker.start_link("stocks")
            {index -1, pid}
        end
    end
end