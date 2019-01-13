defmodule Game.Socket do
  @moduledoc """
  Client to call the socket module
  """

  @socket Application.get_env(:ex_venture, :networking)[:socket_module]

  def echo(state, string) do
    @socket.echo(state.socket, string)
  end

  def prompt(state, string) do
    @socket.prompt(state.socket, string)
  end

  def set_config(state, config) do
    @socket.set_config(state.socket, config)
  end

  def disconnect(state) do
    @socket.disconnect(state.socket)
  end

  def set_character_id(state, character_id) do
    @socket.set_character_id(state.socket, character_id)
  end

  def tcp_option(state, option, enabled) do
    @socket.tcp_option(state.socket, option, enabled)
  end

  def nop(state) do
    @socket.nop(state.socket)
  end

  def push_gmcp(state, module, data) do
    @socket.push_gmcp(state.socket, module, data)
  end
end
