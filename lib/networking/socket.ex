defmodule Networking.Socket do
  @moduledoc """
  Socket behaviour

  Expected functions for a socket to use.
  """

  @doc """
  For session recovery, set the character id of the socket
  """
  @callback set_character_id(socket :: pid(), character_id :: integer()) :: :ok

  @callback set_config(socket :: pid(), config :: map()) :: :ok

  @callback echo(socket :: pid(), message :: String.t()) :: :ok

  @callback prompt(socket :: pid(), message :: String.t()) :: :ok

  @callback disconnect(socket :: pid()) :: :ok

  @callback tcp_option(socket :: pid(), option :: atom, enabled :: boolean) :: :ok

  @callback nop(socket :: pid()) :: :ok

  @callback push_gmcp(socket :: pid(), module :: String.t(), data :: String.t()) :: :ok

  defmacro __using__(_opts) do
    quote do
      @socket Application.get_env(:ex_venture, :networking)[:socket_module]
    end
  end
end
