defmodule InventoryService.Stock do
  use GenServer

  defstruct auto_id: 1, products: %{}

  def start(market_name) do
    GenServer.start(__MODULE__, market_name)
  end

  def add_product(stock_pid, product) do
    GenServer.call(stock_pid, {:add_product, product})
  end

  def update_product(stock_pid, product_id, update_product) do
    GenServer.cast(stock_pid, {:update_product, product_id, update_product})
  end

  def delete_product(stock_pid, product_id) do
    GenServer.cast(stock_pid, {:delete_product, product_id})
  end

  def get_product(stock_pid, product_id) do
    GenServer.call(stock_pid, {:get_product, product_id})
  end

  @impl GenServer
  def init(market_name) do
    send(self(), {:real_init, market_name})
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:add_product, product}, _from, {name, stock}) do
    new_product = Map.put(stock.products, stock.auto_id, product)
    new_state =  %Market.Stock{stock | products: new_product, auto_id: stock.auto_id + 1}
    Market.Database.store(name, new_state)
    {
      :reply,
      stock.auto_id,
      {name, new_state}
    }
  end

  @impl GenServer
  def handle_cast({:update_product, product_id, update_product}, {name, stock}) do
    updated_products = Map.replace(stock.products, product_id, update_product)
    new_state = %InventoryService.Stock{stock | products: updated_products}

    product_key_atom = for {key, val} <- update_product, into: %{} do
      if is_binary(key) do
        {String.to_atom(key), val}
      else
        {key, val}
      end
    end

    InventoryService.Database.update(product_key_atom, product_id)
>>>>>>> Stashed changes
    {
      :noreply,
      {name, new_state}
    }
  end

  @impl GenServer
    def handle_cast({:delete_product, product_id}, {name, stock}) do
    updated_products = Map.delete(stock.products, product_id)
    new_state = %Market.Stock{stock | products: updated_products}
    Market.Database.store(name, new_state)
    {
      :noreply,
      {name, new_state}
    }
  end

  @impl GenServer
  def handle_cast({:buy_product, product_id, quantity}, stock) do
    product = Map.get(stock.products, product_id)
    case product.quantity do
      0 ->
        InventoryService.RabbitMQProducer.publish("erro ao efetuar compra, produto esgotado")

      product_quantity when product_quantity < quantity ->
        InventoryService.RabbitMQProducer.publish("erro ao efetuar compra, quantidade insuficiente")

      _ ->
        update_product = product.quantity - quantity
        GenServer.cast(self(), {:update_product, product_id, update_product})
    end 
    {
      :reply,
      Map.get(stock.products, product_id),
      {name, stock}
    }
  end

  @impl GenServer
  def handle_cast({:get_all}, stock) do
    InventoryService.RabbitMQProducer.publish(message.meta, stock.products)
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_info({:decide_process, message}, _stock) do
    {:ok, _message} = Genserver.call(self(), {:get_database, message})
    case message["process"] do
      "update" ->
        GenServer.cast(self(), {:update_product, message["product_id"], message["update_product"]})
      "delete" ->
        GenServer.cast(self(), {:delete_product, message["product_id"]})
      "add" ->
        product_id = GenServer.call(self(), {:add_product, message["product"]})
        send(InventoryService.Cache, {:product_created, self(), product_id})
      "buy_product" ->
        GenServer.cast(self(), {:buy_product, message["product_id"], message["quantity"]})
      "get_all" ->
        GenServer.cast(self(), {:get_all, message})
    end
    {:noreply, {market_name, Market.Database.get(market_name) || %Market.Stock{}}}
  end
end 