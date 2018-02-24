defmodule Game.Command.Socials do
  @moduledoc """
  The "mail" command
  """

  use Game.Command

  alias Game.Format
  alias Game.Socials

  For
  commands(["socials"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Socials"
  def help(:short), do: "Say prewritten emotes to a room"

  def help(:full) do
    """
    #{help(:short)}

    View a list of available socials
    [ ] > {white}socials{/white}

    Look at what a social will send
    [ ] > {white}social smile{/white}
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
        lines = [
          "\"#{social}\" could not be found.",
          "Please make sure to enter the social command. See {white}socials{/white} for the list."
        ]

        state.socket |> @socket.echo(Format.wrap(Enum.join(lines)))

      social ->
        state.socket |> @socket.echo(Format.social(social))
    end
  end
end
