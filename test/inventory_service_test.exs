defmodule InventoryServiceTest do
  use ExUnit.Case
  doctest InventoryService

  test "greets the world" do
    assert InventoryService.hello() == :world
  end
end
