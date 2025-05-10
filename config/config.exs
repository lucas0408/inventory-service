import Config

config :inventory_service, InventoryService.Repo,
  pool_size: 10,
  adapter: Ecto.Adapters.Postgres,
  database: "postgres",
  username: "postgres",
  password: "inventory_postgres",
  hostname: "127.0.0.1", 
  show_sensitive_data_on_connection_error: true,
  port: 5432,
  pool_timeout: 15000,    
  connect_timeout: 15000 

config :inventory_service, ecto_repos: [InventoryService.Repo]