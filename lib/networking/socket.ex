defmodule Networking.Socket do
  @callback echo(socket :: pid, message :: String.t) :: :ok
  @callback prompt(socket :: pid, message :: String.t) :: :ok
  @callback disconnect(socket :: pid) :: :ok

  defmacro __using__(_opts) do
    quote do
      @socket Application.get_env(:ex_mud, :networking)[:socket_module]
    end
  end
end
