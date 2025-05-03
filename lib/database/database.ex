defmodule InventoryService.Database do
    use GenServer

    def start_link(table_name) do
        GenServer.start(__MODULE__, table_name, name: __MODULE__)
    end

    def create(product, meta) do
        product.product_name
        |> chose_worker()
        |> InventoryService.DatabaseWorker.create(product, meta)
    end
    
    def get_product(id) do
        id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get_product(id)
    end
    
    def get_all(meta) do
        Enum.random(1..100)
        |> chose_worker()
        |> InventoryService.DatabaseWorker.get_all(meta)
    end

    def update(update_product, product_id, meta) do
        product_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.update(update_product, product_id, meta)
    end

    def delete(product_id, meta) do
        product_id
        |> chose_worker()
        |> InventoryService.DatabaseWorker.delete(product_id, meta)
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
        for index <- 1..10, into: %{} do
            {:ok, pid} = InventoryService.DatabaseWorker.start(table_name)
            {index - 1, pid}
        end
    end
end