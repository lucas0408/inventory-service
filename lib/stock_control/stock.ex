defmodule InventoryService.Stock do
  use GenServer

  defstruct auto_id: 1, products: %{}

  # Funções cliente para interação com o GenServer
  def add_product(pid, product) do
    GenServer.cast(pid, {:add_product, product})
  end

  def update_product(pid, product_id, update_product) do
    GenServer.cast(pid, {:update_product, product_id, update_product})
  end

  def delete_product(pid, product_id) do
    GenServer.cast(pid, {:delete_product, product_id})
  end

  def buy_product(pid, product_id, quantity) do
    GenServer.cast(pid, {:buy_product, product_id, quantity})
  end

  def get_all(pid, message) do
    GenServer.cast(pid, {:get_all, message})
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:add_product, product}, stock) do
    product_key_atom = for {key, val} <- product, into: %{}, do: {String.to_atom(key), val}
    InventoryService.Database.create(product_key_atom)
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_cast({:update_product, product_id, update_product}, stock) do
    product_key_atom = for {key, val} <- update_product, into: %{} do
      if is_binary(key) do
        {String.to_atom(key), val}
      else
        {key, val}
      end
    end

    InventoryService.Database.update(product_key_atom, product_id)
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_cast({:delete_product, product_id}, stock) do
    InventoryService.Database.delete(product_id)
    {
      :noreply,
       stock
    }
  end

  @impl GenServer
  def handle_cast({:buy_product, product_id, quantity}, stock) do
  end

  @impl GenServer
  def handle_cast({:get_all, message}, stock) do
    InventoryService.Database.get_all(Enum.random(1..100))
    {
      :noreply,
      stock
    }
  end

end