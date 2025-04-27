defmodule InventoryService.Stock do
  use GenServer

  defstruct auto_id: 1, products: %{}

  # Funções cliente para interação com o GenServer
  def add_product(pid, product) do
    GenServer.call(pid, {:add_product, product})
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

  # Função para formatar valores
  defp format_value(%Decimal{} = value), do: Decimal.to_string(value)
  defp format_value(%Date{} = date), do: Date.to_string(date)
  defp format_value(value), do: value

  # Inicialização do GenServer
  def start(message) do
    GenServer.start(__MODULE__, message)
  end

  @impl GenServer
  def init(message) do
    send(self(), {:real_init, message})
    {:ok, nil}
  end

  # Callbacks do GenServer (handle_call, handle_cast, handle_info)
  @impl GenServer
  def handle_call({:add_product, product}, _from, stock) do
    new_product = Map.put(stock.products, stock.auto_id, product)
    send(InventoryService.Cache, {:product_created, self(), stock.auto_id})
    new_state =  %InventoryService.Stock{stock | products: new_product, auto_id: stock.auto_id + 1}
    product_key_atom = for {key, val} <- product, into: %{}, do: {String.to_atom(key), val}
    InventoryService.Database.create(stock.auto_id, Map.put(product_key_atom, :id, stock.auto_id))
    {
      :reply,
      stock.auto_id,
      new_state
    }
  end

  @impl GenServer
  def handle_cast({:update_product, product_id, update_product}, stock) do
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
    {
      :noreply,
      new_state
    }
  end

  @impl GenServer
  def handle_cast({:delete_product, product_id}, stock) do
    updated_products = Map.delete(stock.products, product_id)
    new_state = %InventoryService.Stock{stock | products: updated_products}
    InventoryService.Database.delete(product_id)
    {
      :noreply,
       new_state
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
        update_product(self(), product_id, update_product)
    end 
    {
      :noreply,
       stock
    }
  end

  @impl GenServer
  def handle_cast({:get_all, message}, stock) do
    InventoryService.RabbitMQProducer.publish(message["meta"], stock.products)
    {
      :noreply,
      stock
    }
  end

  @impl GenServer
  def handle_info({:real_init, message}, _stock) do
    products_list = InventoryService.Database.get_all(Enum.random(1..100))
    products_map = products_list
    |> Enum.reduce(%{}, fn product, acc ->
      string_product = product
      |> Map.drop([:id, :inserted_at, :updated_at])
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

    {:noreply, %InventoryService.Stock{auto_id: next_id, products: products_map}}
  end

  @impl true
  def handle_info(:timeout, stock) do
    send(InventoryService.Cache, {:product_created, self(), stock.auto_id})
    {:stop, :normal, stock}
  end

  @impl GenServer
  def handle_info({:decide_process, message}, stock) do
    case message["process"] do
      "update" ->
        update_product(self(), message["product_id"], message["update_product"])
      
      "delete" ->
        delete_product(self(), message["product_id"])
      
      "add" ->
        IO.inspect("eu passei por aqui")
        product_id = add_product(self(), message["product"])
        send(InventoryService.Cache, {:product_created, self(), product_id})
      
      "buy_product" ->
        buy_product(self(), message["product_id"], message["quantity"])
      
      "get_all" ->
        get_all(self(), message)
    end
    
    {:noreply, stock}
  end
end