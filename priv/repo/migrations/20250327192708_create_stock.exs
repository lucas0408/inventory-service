defmodule Stock.Repo.Migrations.CreateStock do
  use Ecto.Migration

  def change do
    create table(:stocks, primary_key: false) do
      add :id, :integer, primary_key: true
      add :market_id, :string
      add :product_name, :string
      add :quantity, :integer
      add :purchase_price, :decimal
      add :sale_price, :decimal
      add :expiration_date, :date
      
      timestamps(type: :utc_datetime)
    end
  end
end