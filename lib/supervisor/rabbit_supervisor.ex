defmodule InventoryService.RabbitSupervisor do
  use Supervisor
  def start_link(chan) do
    Supervisor.start_link(__MODULE__, chan)
  end

  def init(chan) do
    processes = [
      %{
        id: InventoryService.RabbitMQConsume,
        start: {InventoryService.RabbitMQConsume, :start_link, [chan]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker,
        modules: [InventoryService.RabbitMQConsume]
      },
      %{
        id: InventoryService.RabbitMQProducer,
        start: {InventoryService.RabbitMQProducer, :start_link, [chan]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker,
        modules: [InventoryService.RabbitMQProducer]
      }
    ]

    Supervisor.init(processes, strategy: :one_for_one)
  end
end