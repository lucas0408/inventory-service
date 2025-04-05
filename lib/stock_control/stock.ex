defmodule InventoryService.Stock do
  use GenServer

  defstruct auto_id: 1, products: %{}

  defp format_value(%Decimal{} = value), do: Decimal.to_string(value)
  defp format_value(%Date{} = date), do: Date.to_string(date)
  defp format_value(value), do: value

  def start(message) do
    GenServer.start(__MODULE__, message)
  end

  @impl GenServer
  def init(message) do
    send(self(), {:real_init, message})
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:add_product, product}, _from, {market_id, stock}) do
    new_product = Map.put(stock.products, stock.auto_id, product)
    new_state =  %InventoryService.Stock{stock | products: new_product, auto_id: stock.auto_id + 1}
    product_key_atom = for {key, val} <- product, into: %{}, do: {String.to_atom(key), val}
    InventoryService.Database.create(market_id, Map.put(product_key_atom, :id, stock.auto_id))
    {
      :noreply,
      {market_id, new_state}
    }
  end

  @impl GenServer
  def handle_cast({:update_product, product_id, update_product}, {market_id, stock}) do
    updated_products = Map.replace(stock.products, product_id, update_product)
    new_state = %InventoryService.Stock{stock | products: updated_products}
    product_key_atom = for {key, val} <- update_product, into: %{}, do: {String.to_atom(key), val}
    InventoryService.Database.update(market_id, product_key_atom, product_id)
    {
      :noreply,
      {market_id, new_state}
    }
  end

  @impl GenServer
    def handle_cast({:delete_product, product_id}, {market_id, stock}) do
    updated_products = Map.delete(stock.products, product_id)
    new_state = %InventoryService.Stock{stock | products: updated_products}
    InventoryService.Database.delete(market_id, product_id)
    {
      :noreply,
      {market_id, new_state}
    }
  end

  @impl GenServer
  def handle_cast({:get_product, product_id}  , {market_id, stock}) do
    InventoryService.RabbitMQProducer.publish(Map.get(stock.products, product_id))
    {
      :noreply,
      {market_id, stock}
    }
  end

  @impl GenServer
  def handle_cast({:get_all}, {market_id, stock}) do
    InventoryService.RabbitMQProducer.publish(stock.products)
    {
      :noreply,
      {market_id, stock}
    }
  end

  @impl GenServer
  def handle_info({:real_init, message}, _stock) do
    products_list = InventoryService.Database.get_all(message["market_id"])
    products_map = products_list
    |> Enum.reduce(%{}, fn product, acc ->
      string_product = product
      |> Map.drop([:id, :market_id, :inserted_at, :updated_at])
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.put(acc, Atom.to_string(k), format_value(v))
      end)
      
      Map.put(acc, product.id, string_product)
    end)

    next_id = if Enum.empty?(products_list), do: 1, else: 
      products_list
      |> Enum.map(& &1.id)
      |> Enum.max()
      |> Kernel.+(1)

      
    send(self(), {:decide_process, message})

   {:noreply, {message["market_id"], %InventoryService.Stock{auto_id: next_id, products: products_map}}}
  end

  @impl GenServer
  def handle_info({:decide_process, message}, {market_id, stock}) do
    case message["process"] do
      "update" ->
        GenServer.cast(self(), {:update_product, message["product_id"], message["update_product"]})
      "delete" ->
        GenServer.cast(self(), {:delete_product, message["product_id"]})
      "add" ->
        GenServer.cast(self(), {:add_product, message["product"]})
      "get" ->
        GenServer.cast(self(), {:get_product, message["product_id"]})
      "get_all" ->
        GenServer.cast(self(), {:get_all})

    end
    {:noreply, {market_id, stock}}
  end
end 