defmodule InventoryService.RabbitMQConfig do
  use GenServer
  use AMQP

  @exchange    "default"
  @queue       "default.email"
  @queue_error "#{@queue}_error"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def publish(message) do
    GenServer.handle_cast(__MODULE__, {:publish, message})
  end

  @impl true
  def init(_opts) do
    options = [
      host: "kebnekaise.lmq.cloudamqp.com",
      port: 5671,
      virtual_host: "ymuldtjc",
      username: "ymuldtjc",
      password: "6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72",
      ssl_options: [verify: :verify_none], # Necessário para conexão segura
      name: "my-conn"
    ]
    {:ok, conn} = Connection.open(options)
    
    {:ok, chan} = Channel.open(conn)

    :ok = Exchange.direct(chan, @exchange, durable: true)

    
    IO.inspect(chan)

    {:ok, _} = Queue.declare(chan, @queue, durable: true)

    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)

    :ok = Queue.bind(chan, @queue, @exchange)

    {:ok, _consumer_tag} = Basic.consume(chan, @queue)

    {:ok, chan}
  end

  @impl true
  def handle_info({:basic_deliver, payload, _meta}, chan) do
    try do
      message = Jason.decode!(payload)
      
      IO.inspect(message)

      Basic.ack(chan, _meta.delivery_tag)
    catch
      _ ->
        Basic.reject(chan, _meta.delivery_tag, requeue: false)
    end

    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Função para publicar mensagens
  def handle_cast({:publish, message}, chan) do
    options = [
      host: "kebnekaise.lmq.cloudamqp.com",
      port: 5671, 
      virtual_host: "ymuldtjc",
      username: "ymuldtjc",
      password: "6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72",
      ssl_options: [verify: :verify_none], # Necessário para conexão segura
      name: "my-conn"
    ]
    {:ok, conn} = Connection.open(options)
    {:ok, chan} = Channel.open(conn)

    # Converte mensagem para JSON
    payload = Jason.encode!(message)

    # Publica a mensagem no exchange
    Basic.publish(chan, @exchange, "", payload)
    {:noreply, chan}
  end
end