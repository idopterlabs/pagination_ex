import Config

config :tailwind, :version, "3.4.6"

if Mix.env() != :test do
  import_config "#{Mix.env()}.exs"
end
