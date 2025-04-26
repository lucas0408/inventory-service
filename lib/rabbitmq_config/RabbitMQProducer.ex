defmodule InventoryService.RabbitMQProducer do
    use GenServer
    use AMQP

    def start_link(chan) do
        GenServer.start(__MODULE__, chan, name: __MODULE__)
    end

    def publish_email_queue(message) do
        GenServer.cast(__MODULE__, {:publish_email_queue, message})
    end

    def publish_user_queue(message, meta) do
        GenServer.cast(__MODULE__, {:publish_user_queue, message, meta})
    end

    @imp GenServer
    def init(chan) do
        {:ok, chan}
    end

    @impl true
    def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
    end

    # Função para publicar mensagens
    @impl true
    def handle_cast({:publish_user_queue, message, meta}, chan) do
        try do
            if meta.properties.reply_to do
            response = Jason.encode!(message)
            
            reply_props = %{
                correlation_id: meta.properties.correlation_id
            }
            
            AMQP.Basic.publish(chan, "", meta.properties.reply_to, response, reply_props)
            end
            
            Basic.ack(chan, meta.delivery_tag)
        catch
            error ->
            IO.inspect(error, label: "Error processing message")
            Basic.reject(chan, meta.delivery_tag, requeue: false)
        end
    end
end