defmodule Test.Networking.Socket do
  def echo(_socket, _message), do: :ok
  def prompt(_socket, _message), do: :ok
  def disconnect(_socket), do: :ok
end
