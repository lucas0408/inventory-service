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
        case HashDict.fetch(cache, message["market_id"]) do
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
                    HashDict.put(cache, message["market_id"], pid_process)
                }
        end
    end
end