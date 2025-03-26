defmodule InventoryService.RabbitMQExample do
  use GenServer
  use AMQP

  @exchange    ""
  @queue       "resource.inventory"
  @queue_error "#{@queue}_error"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @impl true
  def init(_opts) do
    {:ok, conn} = Connection.open("amqps://ymuldtjc:6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72@kebnekaise.lmq.cloudamqp.com/ymuldtjc")
    {:ok, chan} = Channel.open(conn)

    :ok = Exchange.direct(chan, @exchange, durable: true)

    {:ok, _} = Queue.declare(chan, @queue, durable: true)

    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)

    # Bind da fila com o exchange
    :ok = Queue.bind(chan, @queue, @exchange)

    # Configura o consumo da fila
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)

    {:ok, chan}
  end

  # Callback para mensagens recebidas
  @impl true
  def handle_info({:basic_deliver, payload, _meta}, chan) do
    # Processa a mensagem recebida
    try do
      # Converte payload para termo Elixir
      message = Jason.decode!(payload)
      
      # Lógica de processamento da mensagem
      IO.puts "Mensagem recebida: #{inspect(message)}"

      # Confirma o processamento da mensagem
      Basic.ack(chan, _meta.delivery_tag)
    catch
      # Tratamento de erros
      _ ->
        # Em caso de erro, rejeita a mensagem e envia para fila de erros
        Basic.reject(chan, _meta.delivery_tag, requeue: false)
    end

    {:noreply, chan}
  end

  # Função para publicar mensagens
  def publish(message) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)

    # Converte mensagem para JSON
    payload = Jason.encode!(message)

    # Publica a mensagem no exchange
    Basic.publish(chan, @exchange, "", payload)
  end
end