defmodule Networking.SocketCase do
  use ExUnit.CaseTemplate

  defmacro __using__(_opts) do
    quote do
      @socket Test.Networking.Socket

      setup do
        socket = :socket
        @socket.clear_messages
        {:ok, %{socket: socket}}
      end
    end
  end
end
