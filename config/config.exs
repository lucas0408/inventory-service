import Config

config :inventory_service, InventoryService.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "postgres",
  username: "postgres",
  password: "inventory_postgres",
  hostname: "localhost",
  port: 5433

config :inventory_service, ecto_repos: [InventoryService.Repo]