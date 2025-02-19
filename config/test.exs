import Config

config :pagination_ex,
  ecto_repos: [PaginationEx.CoreTest.TestRepo],
  repo: PaginationEx.CoreTest.TestRepo

config :logger, level: :warning
