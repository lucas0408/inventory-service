defmodule InventoryService.RabbitMQConfig do
  use GenServer
  use AMQP

  @exchange    "default"
  @queue       "default.product"
  @queue       "default.product"
  @options      options = [
                  host: "kebnekaise.lmq.cloudamqp.com",
                  port: 5672, 
                  virtual_host: "ymuldtjc",
                  username: "ymuldtjc",
                  password: "6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72"
                ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do

    {:ok, conn} = Connection.open(@options)
    
    {:ok, chan} = Channel.open(conn)

    #Configura um exchange, com seu nome, e durabilidade
    :ok = Exchange.direct(chan, @exchange, durable: true)

    #declara uma fila, com o nome e sua persistencia
    {:ok, _} = Queue.declare(chan, @queue, durable: true)

    {:ok, consumer_pid} = InventoryService.RabbitMQConsume.start_link(chan)

    {:ok, producer_pid} = InventoryService.RabbitMQProducer.start_link(chan)

    #Binda a fila com o exchange
    :ok = Queue.bind(chan, @queue, @exchange)

    #Registra um processo consumidor da fila, caso não
    #seja passado o consumer_pid no final, por padrão ele pegara o pid do processo atual
    {:ok, _consumer_tag} = Basic.consume(chan, @queue, consumer_pid)

    {:ok, chan}
  end
end