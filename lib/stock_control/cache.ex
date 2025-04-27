defmodule InventoryService.Cache do
    use GenServer

    def start_link(_opts) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def decide_server_pid(message) do
        GenServer.cast(__MODULE__, {:decide_server_pid, message})
    end

    @impl GenServer
    def init(_) do
        {:ok, HashDict.new}
    end

    @impl GenServer
    def handle_cast({:decide_server_pid, message}, cache) do
        case message["process"] do
        "update" ->
            {:ok, pid} = HashDict.fetch(cache, message["product_id"])
            InventoryService.Stock.update_product(pid, message["product_id"], message["update_product"])
            {
                :noreply,
                cache
            }
        
        "delete" ->
            {:ok, pid} = HashDict.fetch(cache, message["product_id"])
            InventoryService.Stock.delete_product(pid, product_id)
            {
                :noreply,
                cache
            }
        
        "add" ->
            {:ok, pid} = InventoryService.Stock.start(message)
            InventoryService.Stock.add_product(pid, message["product"])
            {
                :noreply,
                cache
            }
        
        "buy_product" ->
            {:ok, pid} = HashDict.fetch(cache, message["product_id"])
            InventoryService.Stock.buy_product(pid, product_id, quantity)
            {
                :noreply,
                cache
            }
        "get_all" ->
            {:ok, pid} = InventoryService.Stock.start(message)
            InventoryService.Stock.get_all(pid, message["product"])
            {
                :noreply,
                cache
            }
        end
    end

    @impl GenServer
    def handle_info({:product_created, pid_process, product_id}, cache) do
        {
            :noreply,
            HashDict.put(cache, product_id, pid_process)
        }
    end

end