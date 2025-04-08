defmodule InventoryService.Database do
    use GenServer

    def start_link(_opts) do
        GenServer.start(__MODULE__, nil, name: __MODULE__)
    end

    def create(product, product_id) do
        product_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.create(product)
    end

    
    def get_all(random) do
        random
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get_all()
    end

    def update(update_product, product_id) do
        product_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.update(update_product, product_id)
    end

    def delete(product_id) do
        product_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.delete(product_id)
    end

    defp chose_worker(market_id) do
        GenServer.call(__MODULE__, {:chose_worker, market_id})
    end

    @impl GenServer
    def init(table_name) do
        {:ok, gen_workers(table_name)}
    end

    @impl GenServer
    def handle_call({:chose_worker, market_id}, _from, workers) do
        index = :erlang.phash2(market_id, 3)
        {:reply, Map.get(workers, index), workers}
    end


    defp gen_workers(table_name) do
        for index <- 1..3, into: %{} do
            {:ok, pid} = InventoryService.DatabaseWorker.start(table_name)
            {index - 1, pid}
        end
    end
end