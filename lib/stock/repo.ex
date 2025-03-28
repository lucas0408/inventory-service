defmodule Stock.Repo do
  use Ecto.Repo,
    otp_app: :inventory_service,
    adapter: Ecto.Adapters.Postgres
end
