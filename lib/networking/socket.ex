defmodule Networking.Socket do
  @callback echo(socket :: pid, message :: String.t) :: :ok
  @callback prompt(socket :: pid, message :: String.t) :: :ok
  @callback disconnect(socket :: pid) :: :ok
  @callback tcp_option(socket :: pid, option :: atom, enabled :: boolean) :: :ok

  defmacro __using__(_opts) do
    quote do
      @socket Application.get_env(:ex_venture, :networking)[:socket_module]
    end
  end
end
