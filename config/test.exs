use Mix.Config

config :ex_mud, :networking,
  server: false,
  socket_module: Test.Networking.Socket
