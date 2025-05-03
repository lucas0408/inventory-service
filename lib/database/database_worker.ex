defmodule InventoryService.DatabaseWorker do
  use GenServer
  alias InventoryService.Repo

  def start(worker_id) do
    GenServer.start(__MODULE__, table_name, name: via_tuple(worker_id))
  end

  def via_tuple(worker_id) do
    {:via, Inventory., {:database_worker, worker_id}}
  end

  def get_all(worker_pid) do
    GenServer.call(via_tuple(worker_id), {:get_all})
  end

  def update(worker_pid, update_product, product_id) do
    GenServer.cast(via_tuple(worker_id), {:update, update_product, product_id})
  end

  def create(worker_pid, product) do
    GenServer.cast(via_tuple(worker_id), {:create, product})
  end

  def delete(worker_pid, id) do
    GenServer.cast(via_tuple(worker_id), {:delete, id})
  end

  @impl GenServer
  def init(table_name) do
    {:ok, table_name}
  end

  @impl GenServer
  def handle_call({:get_all}, _from, table_name) do
    query = "SELECT * FROM #{table_name}"
    result = Ecto.Adapters.SQL.query!(Repo, query, [])
    |> format_result()
    
    {:reply, result, table_name}
  end

  @impl GenServer
  def handle_cast({:create, product}, table_name) do
    columns = Map.keys(product) |> Enum.join(", ")
    placeholders = 1..map_size(product) |> Enum.map(&"$#{&1}") |> Enum.join(", ")
    values = Map.values(product)
    
    query = "INSERT INTO #{table_name} (#{columns}, inserted_at, updated_at) VALUES (#{placeholders}, NOW(), NOW())"
    Ecto.Adapters.SQL.query!(Repo, query, values)
    
    {:noreply, table_name}
  end

  @impl GenServer
  def handle_cast({:update, update_product, id}, table_name) do
    {columns, values} = Map.to_list(update_product)
    |> Enum.with_index(1)
    |> Enum.map_reduce([], fn {{k, v}, idx}, acc -> {"#{k} = $#{idx}", [v | acc]} end)
    
    set_clause = Enum.join(columns, ", ")
    query = "UPDATE #{table_name} SET #{set_clause}, updated_at = NOW() WHERE id = $#{length(values) + 1}"
    
    Ecto.Adapters.SQL.query!(Repo, query, values ++ [id])
    
    {:noreply, table_name}
  end

  @impl GenServer
  def handle_cast({:delete, id}, table_name) do
    query = "DELETE FROM #{table_name} WHERE id = $1"
    Ecto.Adapters.SQL.query!(Repo, query, [id])
    
    {:noreply, table_name}
  end

  defp format_result(%{columns: columns, rows: rows}) do
    column_atoms = Enum.map(columns, &String.to_atom/1)
    
    Enum.map(rows, fn row ->
      Enum.zip(column_atoms, row) |> Map.new()
    end)
  end
end