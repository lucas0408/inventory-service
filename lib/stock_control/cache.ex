defmodule InventoryService.Cache do
    use GenServer

    def start do
        GenServer.start(__MODULE__, nil, name: :cache_server)
    end

    def decide_server_pid(cache_pid, message) do
        GenServer.cast(cache_pid, {:decide_server_pid, message})
    end

    @impl GenServer
    def init(_) do
        Market.Database.start
        {:ok, HashDict.new}
    end

    @impl GenServer
    def handle_cast({:decide_server_pid, message}, _from, cache) do
        case HashDict.fetch(cache, message["market_name"]) do
            {:ok, pid_process} ->
                send(pid_process, {:decide_process, message})
                {
                    :noreply,
                    cache
                }
            :error ->
                {:ok, pid_process} = Market.Stock.start(message["market_id"])
                send(pid_process, {:decide_process, message})
                {
                    :noreply,
                    HashDict.put(cache, message["market_id"], pid_process)
                }
        end
    end
end