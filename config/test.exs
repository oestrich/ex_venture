use Mix.Config

config :logger,
  level: :error

config :ex_mud, :networking,
  server: false,
  socket_module: Test.Networking.Socket
