defmodule InventoryService.Database do
  use GenServer

	@db_folder "stocks"
  @pool_size 10

	def start_link(_opts) do
		InventoryService.PoolSupervisor.start_link(@db_folder, @pool_size)
	end

	def create(product, meta) do
		product.product_name
		|> chose_worker()
		|> InventoryService.DatabaseWorker.create(product, meta)
	end

	
	def get_all(meta) do
		:rand.uniform(10)
		|> InventoryService.DatabaseWorker.get_all(meta)
	end

	def update(update_product, product_id, meta) do
		product_id
		|> chose_worker()
		|> InventoryService.DatabaseWorker.update(update_product, product_id, meta)
	end

	def delete(product_id, meta) do
		product_id
		|> chose_worker()
		|> InventoryService.DatabaseWorker.delete(product_id, meta)
	end

	def chose_worker(market_id) do
		:erlang.phash2(market_id, @pool_size) + 1
	end
end