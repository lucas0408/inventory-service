defmodule InventoryService.DatabaseWorker do
  use GenServer
  alias InventoryService.Repo

  def start_link(table_name, worker_id) do
    IO.inspect("oii")
    GenServer.start_link(__MODULE__, table_name, name: via_tuple(worker_id))
  end

  def via_tuple(worker_id) do
    {:via, InventoryService.ProcessRegistry, {:database_worker, worker_id}}
  end

  def get_all(worker_id) do
    GenServer.call(via_tuple(worker_id), {:get_all})
  end

  def update(worker_id, update_product, product_id) do
    GenServer.cast(via_tuple(worker_id), {:update, update_product, product_id})
  end

  def create(worker_id, product) do
    GenServer.cast(via_tuple(worker_id), {:create, product})
  end

  def delete(worker_id, id) do
    GenServer.cast(via_tuple(worker_id), {:delete, id})
  end

  @impl GenServer
  def init(table_name) do
    IO.inspect(self())
    {:ok, table_name}
  end

  @impl GenServer
  def handle_call({:get_product, id}, _sender, table_name) do
    query = "SELECT * FROM #{table_name} WHERE id = $1"
    case Ecto.Adapters.SQL.query(Repo, query, [id]) do
      {:ok, result} ->
  
        {:reply, Enum.map(result.rows, fn row -> transform_row(row) end), table_name}

      {:error, reason} -> 
        {:reply, reason, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:get_all, meta}, table_name) do
    query = "SELECT * FROM #{table_name}"
    case Ecto.Adapters.SQL.query(Repo, query, []) do
      {:ok, result} ->
        IO.inspect(Enum.map(result.rows, fn row -> transform_row(row) end))
        {:noreply, table_name}

      {:error, reason} -> 
        InventoryService.RabbitMQProducer.publish_user_queue(%{status: "faild_list", reason: reason}, meta)
        {:noreply, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:create, product, meta}, table_name) do
    columns = Map.keys(product) |> Enum.join(", ")
    placeholders = 1..map_size(product) |> Enum.map(&"$#{&1}") |> Enum.join(", ")
    values = Map.values(product)
    
    query = "INSERT INTO #{table_name} (#{columns}, inserted_at, updated_at) VALUES (#{placeholders}, NOW(), NOW())"

    case Ecto.Adapters.SQL.query(Repo, query, values) do
      {:ok, result} -> 
        IO.inspect(result)
        {:noreply, table_name}
      {:error, reason} -> 
        IO.inspect(reason)
        InventoryService.RabbitMQProducer.publish_user_queue(%{status: "faild_created", reason: reason}, meta)
        {:noreply, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:update, update_product, id, meta}, table_name) do
    columns = Map.to_list(update_product)
    |> Enum.with_index(1)
    |> Enum.map(fn {{k, v}, idx} -> "#{k} = $#{idx}" end)

    values = Map.values(update_product)
    IO.inspect(columns)
    IO.inspect(Map.values(update_product))
    
    set_clause = Enum.join(columns, ", ")
    query = "UPDATE #{table_name} SET #{set_clause}, updated_at = NOW() WHERE id = $#{length(values) + 1}"

    case Ecto.Adapters.SQL.query(Repo, query, values ++ [id]) do
      {:ok, _result} -> {:noreply, table_name}
      {:error, reason} ->
        IO.inspect(reason)
        {:noreply, table_name}
    end
  end

  @impl GenServer
  def handle_cast({:delete, id, meta}, table_name) do
    query = "DELETE FROM #{table_name} WHERE id = $1"

    case Ecto.Adapters.SQL.query(Repo, query, [id]) do
      {:ok, _result} -> 
        IO.inspect("ok")
        {:noreply, table_name}
      {:error, reason} ->
        IO.inspect(reason)
        {:noreply, table_name}
    end
  end

  defp transform_row(row) do
  %{
    id: Enum.at(row, 0),
    product_name: Enum.at(row, 1),
    quantity: Enum.at(row, 2),
    purchase_price: Decimal.to_float(Enum.at(row, 3)),
    sale_price: Decimal.to_float(Enum.at(row, 4)),     
    expiration_date: Enum.at(row, 5)                 
  }
  end
end
