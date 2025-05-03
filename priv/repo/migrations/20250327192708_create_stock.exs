defmodule Stock.Repo.Migrations.CreateStock do
  use Ecto.Migration

def change do
  create table(:stocks) do
    add :product_name, :string
    add :quantity, :integer
    add :purchase_price, :decimal
    add :sale_price, :decimal
    add :expiration_date, :date
    timestamps(type: :utc_datetime)
  end
  
    create constraint("stocks", "quantity_non_negative", check: "quantity >= 0")
    create constraint("stocks", "purchase_price_non_negative", check: "purchase_price >= 0")
    create constraint("stocks", "sale_price_non_negative", check: "sale_price >= 0")
  end
end