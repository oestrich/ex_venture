defmodule Game.Session.CreateAccount do
  @moduledoc """
  Creating an account workflow

  Asks for basic information to create an account.
  """

  use Networking.Socket

  alias Game.Account
  alias Game.Class
  alias Game.Config
  alias Game.Race
  alias Game.Session.Login
  alias Metrics.PlayerInstrumenter
  alias Web.ErrorHelpers

  @doc """
  Start text for creating an account

  This echos to the socket and ends with asking for the first field.
  """
  @spec start(pid) :: :ok
  def start(socket) do
    message = """
    Welcome to #{Config.game_name()}.
    Thank you for joining!.
    We need a name and password for you to sign up.
    #{random_names()}
    """

    socket |> @socket.echo(String.trim(message))

    socket |> @socket.prompt("Name: ")
  end

  def process(
        password,
        state = %{socket: socket, create: %{name: name, email: email, race: race, class: class}}
      ) do
    socket |> @socket.tcp_option(:echo, true)

    case Account.create(%{name: name, email: email, password: password}, %{
           race: race,
           class: class
         }) do
      {:ok, user} ->
        PlayerInstrumenter.new_character()
        user |> Login.login(socket, state |> Map.delete(:create))

      {:error, changeset} ->
        socket
        |> @socket.echo(
          "There was a problem creating your account.\nPlease start over.\n#{
            changeset_errors(changeset)
          }"
        )

        socket |> @socket.prompt("Name: ")
        state |> Map.delete(:create)
    end
  end

  def process(email, state = %{socket: socket, create: %{name: name, race: race, class: class}}) do
    case email == "" || Regex.match?(~r/.+@.+\..+/, email) do
      true ->
        socket |> @socket.prompt("Password: ")
        socket |> @socket.tcp_option(:echo, false)
        Map.merge(state, %{create: %{name: name, email: email, race: race, class: class}})

      false ->
        socket |> @socket.echo("Invalid email, please enter again")
        socket |> email_prompt()
        Map.merge(state, %{create: %{name: name, race: race, class: class}})
    end
  end

  def process(class, state = %{socket: socket, create: %{name: name, race: race}}) do
    class =
      Class.classes()
      |> Enum.find(fn cls -> String.downcase(cls.name) == String.downcase(class) end)

    case class do
      nil ->
        socket |> class_prompt()
        state

      class ->
        socket |> email_prompt()
        Map.merge(state, %{create: %{name: name, race: race, class: class}})
    end
  end

  def process(race_name, state = %{socket: socket, create: %{name: name}}) do
    race =
      Race.races()
      |> Enum.find(fn race -> String.downcase(race.name) == String.downcase(race_name) end)

    case race do
      nil ->
        socket |> race_prompt
        state

      race ->
        socket |> class_prompt()
        Map.merge(state, %{create: %{name: name, race: race}})
    end
  end

  def process(name, state = %{socket: socket}) do
    case String.contains?(name, " ") do
      true ->
        socket |> @socket.echo("Your name cannot contain spaces. Please pick a new one")
        socket |> @socket.prompt("Name: ")
        state

      false ->
        socket |> race_prompt()
        Map.merge(state, %{create: %{name: name}})
    end
  end

  defp race_prompt(socket) do
    races =
      Race.races()
      |> Enum.map(fn race -> "\t- #{race.name()}" end)
      |> Enum.join("\n")

    socket |> @socket.echo("Now to pick a race. Your options are:\n#{races}")
    socket |> @socket.prompt("Race: ")
  end

  defp class_prompt(socket) do
    classes =
      Class.classes()
      |> Enum.map(fn class -> "\t- #{class.name()}" end)
      |> Enum.join("\n")

    socket |> @socket.echo("Now to pick a class. Your options are:\n#{classes}")
    socket |> @socket.prompt("Class: ")
  end

  defp email_prompt(socket) do
    socket |> @socket.prompt("Email (optional, enter for blank): ")
  end

  defp changeset_errors(%{errors: errors}) do
    errors
    |> Enum.reject(&(elem(&1, 0) == :password_hash))
    |> Enum.map(fn {field, errors} ->
      "#{field}: #{ErrorHelpers.translate_error(errors)}"
    end)
    |> Enum.join("\n")
  end

  defp random_names() do
    case Config.random_character_names() do
      [] ->
        ""

      names ->
        """

        Here are a few names to help you pick one:
        #{Enum.join(names, ", ")}
        """
    end
  end
end
