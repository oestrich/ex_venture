defmodule Game.Command.Socials do
  @moduledoc """
  The "mail" command
  """

  use Game.Command

  import Game.Room.Helpers, only: [find_character: 2]

  alias Game.Format
  alias Game.Socials

  commands(["socials"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Socials"
  def help(:short), do: "Say prewritten emotes to a room"

  def help(:full) do
    """
    #{help(:short)}

    View a list of available socials
    [ ] > {command}socials{/command}

    Look at what a social will send
    [ ] > {command}social smile{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Socials.parse("socials")
      {:list}

      iex> Game.Command.Socials.parse("socials smile")
      {:help, "smile"}

      iex> Game.Command.Socials.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("socials"), do: {:list}
  def parse("socials " <> social), do: {:help, social}
  def parse("social " <> social), do: {:help, social}

  def parse(command) when is_binary(command) do
    Socials.all()
    |> Enum.find(fn social ->
      Regex.match?(~r(^#{social.command}), command)
    end)
    |> parse_social(command)
  end

  defp parse_social(nil, command), do: {:error, :bad_parse, command}

  defp parse_social(social, command) do
    command =
      command
      |> String.replace(~r/^#{social.command}/i, "")
      |> String.trim()

    case command do
      "" -> {social.command}
      command -> {social.command, command}
    end
  end

  @impl Game.Command
  @doc """
  Send mail to players
  """
  def run(command, state)

  def run({:list}, state) do
    socials = Socials.all()
    {:paginate, Format.socials(socials), state}
  end

  def run({:help, social}, state) do
    case Socials.social(social) do
      nil ->
        state |> social_not_found(social)

      social ->
        state.socket |> @socket.echo(Format.social(social))
    end

    :ok
  end

  def run({social}, state) do
    case Socials.social(social) do
      nil ->
        state |> social_not_found(social)

      social ->
        state.socket |> @socket.echo(Format.social_without_target(social, state.user))
    end

    :ok
  end

  def run({social, character_name}, state = %{save: save}) do
    case Socials.social(social) do
      nil ->
        state |> social_not_found(social)

      social ->
        {:ok, room} = @room.look(save.room_id)

        case find_character(room, character_name) do
          {:error, :not_found} ->
            state.socket |> @socket.echo("\"#{character_name}\" could not be found.")

          character ->
            state.socket |> @socket.echo(Format.social_with_target(social, state.user, character))
        end
    end

    :ok
  end

  defp social_not_found(state, social) do
    lines = [
      "\"#{social}\" could not be found.",
      "Please make sure to enter the social command. See {command}socials{/command} for the list."
    ]

    state.socket |> @socket.echo(Format.wrap(Enum.join(lines, " ")))
  end
end
