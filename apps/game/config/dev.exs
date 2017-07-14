use Mix.Config

config :game, :networking,
  server: true,
  socket_module: Networking.Protocol
