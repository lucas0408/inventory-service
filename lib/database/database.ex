defmodule InventoryService.Database do
    use GenServer

    def start_link(_opts) do
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

    
    def get_all(market_id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get_all()
    end

    def update(market_id, update_product, product_id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.update(update_product, market_id)
    end

    def delete(market_id, product_id) do
        market_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.delete(market_id)
    end

    defp chose_worker(market_id) do
        GenServer.call(__MODULE__, {:chose_worker, market_id})
    end

    @impl GenServer
    def init(table_name) do
        {:ok, gen_workers()}
    end

    @impl GenServer
    def handle_call({:chose_worker, market_id}, _from, workers) do
        index = :erlang.phash2(market_id, 3)
        {:reply, Map.get(workers, index), workers}
    end


    defp gen_workers do
        for index <- 1..3, into: %{} do
            {:ok, pid} = InventoryService.DatabaseWorker.start("stocks")
            {index - 1, pid}
        end
    end
end