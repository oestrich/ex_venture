use Mix.Config

config :ex_mud, :networking,
  server: true,
  socket_module: Networking.Protocol
