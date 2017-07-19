defmodule Game.Session.CreateAccount do
  use Networking.Socket

  alias Game.Account
  alias Game.Session.Login

  @doc """
  Start text for creating an account

  This echos to the socket and ends with asking for the first field.
  """
  @spec start(socket :: pid) :: nil
  def start(socket) do
    socket |> @socket.echo("\n\nWelcome to ExVenture.\nThank you for joining!\nWe need a username and password for you to sign up.\n")
    socket |> @socket.prompt("Username: ")
  end

  def process(password, session, state = %{socket: socket, create: %{username: username}}) do
    case Account.create(%{username: username, password: password}) do
      {:ok, user} ->
        user |> Login.login(session, socket, state |> Map.delete(:create))
      {:error, _changeset} ->
        socket |> @socket.echo("There was a problem creating your account.\nPlease start over.")
        state
        |> Map.delete(:create)
    end
  end
  def process(username, _session, state = %{socket: socket}) do
    socket |> @socket.prompt("Password: ")
    Map.merge(state, %{create: %{username: username}})
  end
end
