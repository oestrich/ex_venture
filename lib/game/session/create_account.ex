defmodule Game.Session.CreateAccount do
  @moduledoc """
  Creating an account workflow

  Asks for basic information to create an account.
  """

  use Networking.Socket

  alias Game.Account
  alias Game.Class
  alias Game.Session.Login

  @doc """
  Start text for creating an account

  This echos to the socket and ends with asking for the first field.
  """
  @spec start(socket :: pid) :: :ok
  def start(socket) do
    socket |> @socket.echo("\n\nWelcome to ExVenture.\nThank you for joining!\nWe need a name and password for you to sign up.\n")
    socket |> @socket.prompt("Name: ")
  end

  def process(password, session, state = %{socket: socket, create: %{name: name, class: class}}) do
    socket |> @socket.tcp_option(:echo, true)

    case Account.create(%{name: name, password: password}, %{class: class}) do
      {:ok, user} ->
        user |> Login.login(session, socket, state |> Map.delete(:create))
      {:error, _changeset} ->
        socket |> @socket.echo("There was a problem creating your account.\nPlease start over.")
        socket |> @socket.prompt("Name: ")
        state
        |> Map.delete(:create)
    end
  end
  def process(class, _session, state = %{socket: socket, create: %{name: name}}) do
    class = Class.classes
    |> Enum.find(fn (cls) -> String.downcase(cls.name) == String.downcase(class) end)

    case class do
      nil ->
        socket |> class_prompt
        state
      class ->
        socket |> @socket.prompt("Password: ")
        socket |> @socket.tcp_option(:echo, false)
        Map.merge(state, %{create: %{name: name, class: class}})
    end
  end
  def process(name, _session, state = %{socket: socket}) do
    socket |> class_prompt
    Map.merge(state, %{create: %{name: name}})
  end

  defp class_prompt(socket) do
    classes = Class.classes
    |> Enum.map(fn (class) -> "\t- #{class.name()}" end)
    |> Enum.join("\n")

    socket |> @socket.echo("Now to pick a class. Your options are:\n#{classes}")
    socket |> @socket.prompt("Class: ")
  end
end
