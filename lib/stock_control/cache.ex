defmodule InventoryService.Cache do

	@timeout 60000

	def async_call_square_root(message) do
		Task.async(fn ->
			:poolboy.transaction(
				:worker_stock,
				fn pid -> 
					try do
						case message["process"] do
							"update" ->
									InventoryService.Stock.update_product(pid, message)
							"delete" ->
									InventoryService.Stock.delete_product(pid, message)
							"add" ->
									InventoryService.Stock.add_product(pid, message)
							"buy_product" ->
									InventoryService.Stock.buy_product(pid, message)
							"get_all" ->
									InventoryService.Stock.get_all(pid, message)
						end
					catch
						e, r -> IO.inspect("poolboy transaction caught error: #{inspect(e)}, #{inspect(r)}")
						:ok
					end
				end,
				@timeout
			)
		end)
	end
end