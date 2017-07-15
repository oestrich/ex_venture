defmodule Game.Session.Login do
  use Networking.Socket

  alias Game.Authentication
  alias Game.Session

  def process(password, state = %{socket: socket, login: %{username: username}}) do
    case Authentication.find_and_validate(username, password) do
      {:error, :invalid} ->
        socket |> @socket.echo("Invalid password")
        socket |> @socket.disconnect()
        state
      user ->
        Session.Registry.register(user)

        socket |> @socket.echo("Welcome, #{user.username}")

        state
        |> Map.delete(:login)
        |> Map.put(:user, user)
        |> Map.put(:state, "active")
    end
  end
  def process(message, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    Map.merge(state, %{login: %{username: message}})
  end
end
