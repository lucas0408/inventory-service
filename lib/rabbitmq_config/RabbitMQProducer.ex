defmodule InventoryService.RabbitMQProducer do
    use GenServer
    use AMQP

    @exchange    "default"
    @options      options = [
                host: "kebnekaise.lmq.cloudamqp.com",
                port: 5672, 
                virtual_host: "ymuldtjc",
                username: "ymuldtjc",
                password: "6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72"
            ]

    def start_link(chan) do
        GenServer.start(__MODULE__, chan, name: __MODULE__)
    end

    def publish(message) do
        GenServer.cast(__MODULE__, {:publish, message})
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

        payload = Jason.encode!(message)

        IO.inspect(payload)

        # Publica a mensagem no exchange
        Basic.publish(chan, @exchange, "", "payload")
        {:noreply, chan}
    end
end