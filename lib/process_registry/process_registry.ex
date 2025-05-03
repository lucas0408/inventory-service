defmodule InventoryService.ProcessRegistry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, :process_registry)
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined -> {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def unregister_name(key) do
    GenServer.call(:process_registry, {:unregister_name, key})
  end

  def register_name(key, pid) do
    GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def whereis_name(key) do
    GenServer.call(:process_registry, {:whereis_name, key})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:unregister_name, key}, process_registry) do
    {:reply, key, Map.delete(process_registry, key)}
  end

  def handle_call({:whereis_name, key}, process_registry) do
    {:reply, Map.get(process_registry, key), process_registry}
  end

  def handle_call({:register_name, key, pid}, process_registry) do
    case Map.get(process_registry, key) do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, Map.put(process_registry, key, pid)}
      _ ->
        {:reply, :no, process_registry}
    end
  end

  def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  def deregister_pid(process_registry, pid) do
    final_process = Enum.reduce(process_registry, process_registry, fn {key, value}, registry_acc ->  
      if value == pid do
        Map.delete(registry_acc, key)
      else
        registry_acc
      end
    end)
    final_process
  end

end