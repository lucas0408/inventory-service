defmodule InventoryService.DatabaseWorker do
    use GenServer
    alias InventoryService.Repo

    def start(table_name) do
        GenServer.start(__MODULE__, table_name)
    end

    def get(worker_pid, id) do
        GenServer.call(worker_pid, {:get, id})
    end

    def get_all(worker_pid) do
        GenServer.call(worker_pid, {:get_all})
    end

    def update(worker_pid, update_product, id) do
        GenServer.cast(worker_pid, {:update, update_product, id})
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
    def handle_call({:get, id}, table_name) do
        Repo.get_by(table_name, id: id)
    end

    @impl
    def handle_call({:get_all}, table_name) do
        Repo.all(table_name)
    end

    @impl GenServer
    def handle_cast({:create, product}, table_name) do
      Repo.insert_all(table_name, [
        Map.merge(product, %{
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
        })
    ])
    end

    @impl GenServer
    def handle_cast({:update, update_product, id}, table_name) do
        Repo.update_all(
            from(s in table_name, where: s.id == ^id),
            set: Map.put(update_product, :updated_at, NaiveDateTime.utc_now())
        )
    end

    @impl GenServer
    def handle_cast({:delete, id}, table_name) do
        Repo.delete_all(from(s in table_name, where: s.id == ^id))
    end
end