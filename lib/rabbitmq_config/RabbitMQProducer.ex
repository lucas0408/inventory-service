defmodule InventoryService.RabbitMQProducer do
    use GenServer
    use AMQP

    def start_link(chan) do
        GenServer.start(__MODULE__, chan, name: __MODULE__)
    end

    def publish(message) do
        GenServer.handle_cast(__MODULE__, {:publish, message})
    end

    @imp GenServer
    def init(chan) do
        {:ok, chan}
    end

    # Confirmation sent by the broker after registering this process as a consumer
    def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
        {:noreply, chan}
    end

    # Função para publicar mensagens
    @impl true
    def handle_cast({:publish, message}, chan) do
        {:ok, conn} = Connection.open(@options)
        {:ok, chan} = Channel.open(conn)

        # Converte mensagem para JSON
        payload = Jason.encode!(message)

        # Publica a mensagem no exchange
        Basic.publish(chan, @exchange, "", payload)
        {:noreply, chan}
    end
end