use Mix.Config

config :game, :networking,
  server: false,
  socket_module: Test.Networking.Socket
