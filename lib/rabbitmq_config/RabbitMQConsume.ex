defmodule InventoryService.RabbitMQConsume do
  use GenServer
  use AMQP

  def start_link(chan) do
      GenServer.start(__MODULE__, chan, name: __MODULE__)
  end

  @impl GenServer
  def init(chan) do
      IO.inspect("oii")
      {:ok, chan}
  end

  @impl true
  def handle_info({:basic_deliver, payload, meta}, chan) do
    try do
      case Jason.decode(payload) do
        {:ok, message} ->
          InventoryService.Cache.async_call_square_root(Map.put(message, "meta", meta))
          Basic.ack(chan, meta.delivery_tag)
        {:error, error} ->
          IO.inspect(error, label: "JSON decode error")
          Basic.reject(chan, meta.delivery_tag, requeue: false)
      end
    catch
      error ->
        IO.inspect(error, label: "Error caught")
        Basic.reject(chan, meta.delivery_tag, requeue: false)
    end
    
    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info(message, chan) do
    {:noreply, chan}
  end

end