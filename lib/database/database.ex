defmodule InventoryService.Database do
    use GenServer

	def start_link(_opts) do
			#starting process register in anither branch
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
		:erlang.phash2(market_id, 3)
	end
end