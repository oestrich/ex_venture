defmodule Test.Networking.Socket do
  @behaviour Networking.Socket

  defmodule Helpers do
    @moduledoc """
    Helpers for dealing with the socket in tests
    """

    @doc """
    Assert an echo was sent
    """
    defmacro assert_socket_echo(messages) when is_list(messages) do
      quote do
        assert_receive {:echo, _, recv_message}
        Enum.map(unquote(messages), fn message ->
          assert Regex.match?(~r(#{message})i, recv_message)
        end)
      end
    end

    defmacro assert_socket_echo(message) do
      quote do
        assert_receive {:echo, _, recv_message}
        assert Regex.match?(~r(#{unquote(message)})i, recv_message)
      end
    end

    defmacro refute_socket_echo(message) do
      quote do
        assert_receive {:echo, _, recv_message}
        refute Regex.match?(~r(#{unquote(message)})i, recv_message)
      end
    end

    defmacro refute_socket_echo() do
      quote do
        refute_receive {:echo, _, _}
      end
    end

    defmacro assert_socket_prompt(message) do
      quote do
        assert_receive {:prompt, _, recv_message}
        assert Regex.match?(~r(#{unquote(message)})i, recv_message)
      end
    end

    defmacro assert_socket_no_echo() do
      quote do
        refute_receive {:echo, _, _}
      end
    end

    defmacro assert_socket_gmcp(message) do
      quote do
        assert_receive {:gmcp, _socket, unquote(message)}
      end
    end

    defmacro assert_socket_disconnect() do
      quote do
        assert_receive {:disconnect, _}
      end
    end

    defmacro refute_socket_disconnect() do
      quote do
        refute_receive {:disconnect, _}
      end
    end
  end

  @impl Networking.Socket
  def echo(socket, message) do
    send(self(), {:echo, socket, message})
    :ok
  end

  @impl Networking.Socket
  def prompt(socket, message) do
    send(self(), {:prompt, socket, message})
    :ok
  end

  @impl Networking.Socket
  def disconnect(socket) do
    send(self(), {:disconnect, socket})
    :ok
  end

  @impl Networking.Socket
  def tcp_option(_socket, _option, _enabled), do: :ok

  @impl Networking.Socket
  def push_gmcp(socket, module, data) do
    send(self(), {:gmcp, socket, {module, data}})
    :ok
  end

  @impl Networking.Socket
  def set_character_id(_socket, _character_id), do: :ok

  @impl Networking.Socket
  def set_config(_socket, _config), do: :ok

  @impl true
  def nop(_socket), do: :ok
end
