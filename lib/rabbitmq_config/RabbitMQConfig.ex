defmodule InventoryService.RabbitMQConfig do
  use GenServer
  use AMQP

  @exchange    "default"
  @queue       "default.product"
  @options      [
                  host: "kebnekaise.lmq.cloudamqp.com",
                  port: 5672, 
                  virtual_host: "ymuldtjc",
                  username: "ymuldtjc",
                  password: "6V2cHoCicOdizdhzkSSmb7jVLQ2VEW72"
                ]

  def start_link(_) do
    IO.inspect("init rabbit config")
    {:ok, conn} = Connection.open(@options)
    
    {:ok, chan} = Channel.open(conn)

    #Configura um exchange, com seu nome, e durabilidade
    :ok = Exchange.direct(chan, @exchange, durable: true)

    #declara uma fila, com o nome e sua persistencia
    {:ok, _} = Queue.declare(chan, @queue, durable: true)

    #Binda a fila com o exchange
    :ok = Queue.bind(chan, @queue, @exchange)

    InventoryService.RabbitSupervisor.start_link(chan)
  end
end