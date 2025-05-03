import Config

config :inventory_service, InventoryService.Repo,
<<<<<<< HEAD
  pool_size: 10,
=======
>>>>>>> feature/database
  adapter: Ecto.Adapters.Postgres,
  database: "postgres",
  username: "postgres",
  password: "inventory_postgres",
  hostname: "localhost",
  port: 5433

config :inventory_service, ecto_repos: [InventoryService.Repo]