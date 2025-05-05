defmodule InventoryService.Stock do
  use GenServer

  defstruct auto_id: 1, products: %{}

  # Funções cliente para interação com o GenServer
  def add_product(pid, message) do
    GenServer.cast(pid, {:add_product, message})
  end

  def update_product(pid, message) do
    GenServer.cast(pid, {:update_product, message})
  end

  def delete_product(pid, message) do
    GenServer.cast(pid, {:delete_product, message})
  end

  def buy_product(pid, message) do
    GenServer.cast(pid, {:buy_product, message})
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
  def handle_cast({:add_product, message}, stock) do
    product_key_atom = for {key, val} <- message["product"], into: %{}, do: {String.to_atom(key), val}
    {:ok, expiration_date} = Date.from_iso8601(product_key_atom.expiration_date)
    product = %{product_key_atom | expiration_date: expiration_date}
    InventoryService.Database.create(product, message["meta"])
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_cast({:update_product, message}, stock) do
    product_key_atom = for {key, val} <- message["update_product"], into: %{} do
      if is_binary(key) do
        {String.to_atom(key), val}
      else
        {key, val}
      end
    end

    {:ok, expiration_date} = Date.from_iso8601(product_key_atom.expiration_date)
    update_product = %{product_key_atom | expiration_date: expiration_date}

    InventoryService.Database.update(update_product, message["product_id"], message["meta"])
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_cast({:delete_product, message}, stock) do
    InventoryService.Database.delete(message["product_id"], message["meta"])
    {
      :noreply,
       stock
    }
  end

  @impl GenServer
  def handle_cast({:buy_product, message}, stock) do
    product = hd(InventoryService.Database.get_product(message["product_id"]))
    if product.quantity - message["quantity"] < 0 or message["quantity"] < 0 do
      IO.inspect("mensagem inválida")
      {:noreply, stock}
    else
      update_product = Map.put(product, :quantity, product.quantity - message["quantity"])

      IO.inspect(update_product)

      InventoryService.Database.update(update_product, message["product_id"], message["meta"])
      {:noreply, stock}
    end
  end

  @impl GenServer
  def handle_cast({:get_all, message}, stock) do
    InventoryService.Database.get_all(message["meta"])
    {
      :noreply,
      stock
    }
  end

end