defmodule InventoryService.RabbitMQConsume do
    use GenServer
    use AMQP

    def start_link(chan) do
        GenServer.start(__MODULE__, chan, name: __MODULE__)
    end

    @impl GenServer
    def init(chan) do
        {:ok, chan}
    end

   @impl true
  def handle_info({:basic_deliver, payload, meta}, chan) do
    try do

      message = Jason.decode(payload)

      InventoryService.Cache.decide_server_pid(message)

      Basic.ack(chan, meta.delivery_tag)
    catch
      _ ->
        Basic.reject(chan, meta.delivery_tag, requeue: false)
    end

    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

end