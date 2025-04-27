defmodule InventoryService.DatabaseWorker do
  use GenServer
  alias InventoryService.Repo

  def start(table_name) do
    GenServer.start(__MODULE__, table_name)
  end

  def get_all(worker_pid) do
    GenServer.call(worker_pid, {:get_all})
  end

  def update(worker_pid, update_product, product_id) do
    GenServer.cast(worker_pid, {:update, update_product, product_id})
  end

  def create(worker_pid, product) do
    GenServer.cast(worker_pid, {:create, product})
  end

  def delete(worker_pid, id) do
    GenServer.cast(worker_pid, {:delete, id})
  end

  @impl GenServer
  def init(table_name) do
    {:ok, table_name}
  end

  @impl GenServer
  def handle_call({:get_all}, _from, table_name) do
    query = "SELECT * FROM #{table_name}"
    case Ecto.Adapters.SQL.query(Repo, query, []) do
      {:ok, result} ->
        IO.inspect(Enum.map(result.rows, fn row -> transform_row(row) end))

      {:error, reason} ->
        IO.inspect("Erro ao executar query get_all: #{inspect(reason)}")
        {:reply, {:error, "Erro ao buscar registros."}, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:create, product}, table_name) do
    {:ok, expiration_date} = Date.from_iso8601(product.expiration_date)
    product = %{product | expiration_date: expiration_date}
    columns = Map.keys(product) |> Enum.join(", ")
    placeholders = 1..map_size(product) |> Enum.map(&"$#{&1}") |> Enum.join(", ")
    values = Map.values(product)

    IO.inspect(columns)
    IO.inspect(placeholders)
    IO.inspect(values)
    
    query = "INSERT INTO #{table_name} (#{columns}, inserted_at, updated_at) VALUES (#{placeholders}, NOW(), NOW())"

    case Ecto.Adapters.SQL.query(Repo, query, values) do
      {:ok, result} -> IO.inspect(result)
      {:error, reason} ->
        IO.inspect(reason)
    end
  end

  @impl GenServer
  def handle_cast({:update, update_product, id}, table_name) do
    {columns, values} = Map.to_list(update_product)
    |> Enum.with_index(1)
    |> Enum.map_reduce([], fn {{k, v}, idx}, acc -> {"#{k} = $#{idx}", [v | acc]} end)
    
    set_clause = Enum.join(columns, ", ")
    query = "UPDATE #{table_name} SET #{set_clause}, updated_at = NOW() WHERE id = $#{length(values) + 1}"

    case Ecto.Adapters.SQL.query(Repo, query, values ++ [id]) do
      {:ok, _result} -> {:noreply, table_name}
      {:error, reason} ->
        Logger.error("Erro ao executar query update: #{inspect(reason)}")
        {:noreply, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:delete, id}, table_name) do
    query = "DELETE FROM #{table_name} WHERE id = $1"

    case Ecto.Adapters.SQL.query(Repo, query, [id]) do
      {:ok, _result} -> {:noreply, table_name}
      {:error, reason} ->
        Logger.error("Erro ao executar query delete: #{inspect(reason)}")
        {:noreply, table_name}
    end
  end

  defp format_result(%{columns: columns, rows: rows}) do
    column_atoms = Enum.map(columns, &String.to_atom/1)
    
    Enum.map(rows, fn row ->
      Enum.zip(column_atoms, row) |> Map.new()
    end)
  end

  defp transform_row(row) do
  %{
    id: Enum.at(row, 0),
    product_name: Enum.at(row, 1),
    quantity: Enum.at(row, 2),
    purchase_price: Decimal.to_float(Enum.at(row, 3)),
    sale_price: Decimal.to_float(Enum.at(row, 4)),     
    expiration_date: Enum.at(row, 5),                  
    inserted_at: Enum.at(row, 6),                      
    updated_at: Enum.at(row, 7)                        
  }
end
end
