import Config

config :inventory_service, Stock.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "inventory_service_repo",
  username: "postgres",
  password: "inventory_postgres",
  hostname: "localhost",
  port: 5433

config :inventory_service, ecto_repos: [Stock.Repo]