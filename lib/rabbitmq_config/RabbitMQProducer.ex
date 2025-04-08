defmodule InventoryService.RabbitMQProducer do
    use GenServer
    use AMQP

    @exchange    "default"

    def start_link(chan) do
        GenServer.start(__MODULE__, chan, name: __MODULE__)
    end

    def publish(message) do
        GenServer.cast(__MODULE__, {:publish, message})
    end

    @impl GenServer
    def init(chan) do
        {:ok, chan}
    end

    @impl true
    def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
        {:noreply, chan}
    end

    @impl true
    def handle_cast({:publish, message}, chan) do

        payload = Jason.encode!(message)

        IO.inspect("passei por aqui")

        Basic.publish(chan, @exchange, "", payload)
        {:noreply, chan}
    end
end