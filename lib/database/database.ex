defmodule InventoryService.Database do
  use GenServer

	@db_folder "stocks"
  @pool_size 10

	def start_link(_opts) do
		InventoryService.PoolSupervisor.start_link(@db_folder, @pool_size)
	end

	def create(product, product_id) do
		product_id
		|> chose_worker()
		|> InventoryService.DatabaseWorker.create(product)
	end

	
	def get_all(random) do
		random
		|> chose_worker()
		|> InventoryService.DatabaseWorker.get_all()
	end

	def update(update_product, product_id) do
		product_id
		|> chose_worker()
		|> InventoryService.DatabaseWorker.update(update_product, product_id)
	end

	def delete(product_id) do
		product_id
		|> chose_worker()
		|> InventoryService.DatabaseWorker.delete(product_id)
	end

	def chose_worker(market_id) do
		:erlang.phash2(market_id, @pool_size) + 1
	end
end