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
        case message["product_id"] do
            product_id ->
                case HashDict.fetch(cache, product_id) do
                    {:ok, pid_process} ->
                        send(pid_process, {:decide_process, message})
                        {
                            :noreply,
                            cache
                        }
                    :error ->
                        {:ok, pid_process} = InventoryService.Stock.start(message)
                        {
                            :noreply,
                            HashDict.put(cache, product_id, pid_process)
                        }
                end
            nil ->
                {:ok, _pid_process} = InventoryService.Stock.start(message)
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