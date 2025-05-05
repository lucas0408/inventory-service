defmodule InventoryService.RabbitSupervisor do
  use Supervisor
  def start_link(chan) do
    Supervisor.start_link(__MODULE__, chan)
  end

  def init(chan) do
    processes = [
      worker(
        InventoryService.RabbitMQConsume, [chan]
      ),
      worker(
        InventoryService.RabbitMQProducer, [chan]
      )
    ]

    supervise(processes, strategy: :one_for_one)
  end
end