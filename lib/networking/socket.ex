defmodule Networking.Socket do
  @callback echo(socket :: pid, message :: String.t) :: :ok
  @callback prompt(socket :: pid, message :: String.t) :: :ok
  @callback disconnect(socket :: pid) :: :ok
end
