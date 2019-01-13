defmodule Game.Session.CreateAccount do
  @moduledoc """
  Creating an account workflow

  Asks for basic information to create an account.
  """

  alias Game.Account
  alias Game.Class
  alias Game.Config
  alias Game.Race
  alias Game.Session.Login
  alias Game.Socket
  alias Metrics.PlayerInstrumenter
  alias Web.ErrorHelpers

  @doc """
  Start text for creating an account

  This echos to the socket and ends with asking for the first field.
  """
  def start(state) do
    message = """
    Welcome to #{Config.game_name()}.
    Thank you for joining!.
    We need a name and password for you to sign up.
    #{random_names()}
    """

    message = String.trim(message)

    Socket.echo(state, message)
    Socket.prompt(state, "Name: ")
  end

  def process(password, state = %{create: %{name: name, email: email, race: race, class: class}}) do
    state |> Socket.tcp_option(:echo, true)

    case Account.create(%{name: name, email: email, password: password}, %{
           race: race,
           class: class
         }) do
      {:ok, user, character} ->
        PlayerInstrumenter.new_character()
        user |> Login.login(character, state |> Map.delete(:create))

      {:error, changeset} ->
        state
        |> Socket.echo(
          "There was a problem creating your account.\nPlease start over.\n#{
            changeset_errors(changeset)
          }"
        )

        state |> Socket.prompt("Name: ")
        state |> Map.delete(:create)
    end
  end

  def process(email, state = %{create: %{name: name, race: race, class: class}}) do
    case email == "" || Regex.match?(~r/.+@.+\..+/, email) do
      true ->
        state |> Socket.prompt("Password: ")
        state |> Socket.tcp_option(:echo, false)
        Map.merge(state, %{create: %{name: name, email: email, race: race, class: class}})

      false ->
        state |> Socket.echo("Invalid email, please enter again.")
        state |> email_prompt()
        Map.merge(state, %{create: %{name: name, race: race, class: class}})
    end
  end

  def process(class, state = %{create: %{name: name, race: race}}) do
    class =
      Class.classes()
      |> Enum.find(fn cls -> String.downcase(cls.name) == String.downcase(class) end)

    case class do
      nil ->
        state |> class_prompt()
        state

      class ->
        state |> email_prompt()
        Map.merge(state, %{create: %{name: name, race: race, class: class}})
    end
  end

  def process(race_name, state = %{create: %{name: name}}) do
    race =
      Race.races()
      |> Enum.find(fn race -> String.downcase(race.name) == String.downcase(race_name) end)

    case race do
      nil ->
        state |> race_prompt
        state

      race ->
        state |> class_prompt()
        Map.merge(state, %{create: %{name: name, race: race}})
    end
  end

  def process(name, state) do
    case String.contains?(name, " ") do
      true ->
        state |> Socket.echo("Your name cannot contain spaces. Please pick a new one.")
        state |> Socket.prompt("Name: ")
        state

      false ->
        state |> race_prompt()
        Map.merge(state, %{create: %{name: name}})
    end
  end

  defp race_prompt(state) do
    races =
      Race.races()
      |> Enum.map(fn race -> "\t- #{race.name()}" end)
      |> Enum.join("\n")

    state |> Socket.echo("Now to pick a race. Your options are:\n#{races}")
    state |> Socket.prompt("Race: ")
  end

  defp class_prompt(state) do
    classes =
      Class.classes()
      |> Enum.map(fn class -> "\t- #{class.name()}" end)
      |> Enum.join("\n")

    state |> Socket.echo("Now to pick a class. Your options are:\n#{classes}")
    state |> Socket.prompt("Class: ")
  end

  defp email_prompt(state) do
    state |> Socket.prompt("Email (optional, enter for blank): ")
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
        "\nHere are a few names to help you pick one:\n#{Enum.join(names, ", ")}\n"
    end
  end
end
