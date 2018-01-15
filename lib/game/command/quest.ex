defmodule Game.Command.Quest do
  @moduledoc """
  The "quest" command
  """

  use Game.Command

  alias Game.Quest

  commands [{"quest", ["quests"]}], parse: false

  @impl Game.Command
  def help(:topic), do: "Quest"
  def help(:short), do: "View information about your current quests"
  def help(:full) do
    """
    #{help(:short)}.

    Example:
    [ ] > {white}quest{/white}

    Example:
    [ ] > {white}quest show 1{/white}
    [ ] > {white}quest info 1{/white}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Quest.parse("quest")
      {:list, :active}
      iex> Game.Command.Quest.parse("quests")
      {:list, :active}

      iex> Game.Command.Quest.parse("quest show 10")
      {:show, "10"}
      iex> Game.Command.Quest.parse("quest info 10")
      {:show, "10"}

      iex> Game.Command.Channels.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(command :: String.t) :: {atom}
  def parse(command)
  def parse("quest"), do: {:list, :active}
  def parse("quests"), do: {:list, :active}
  def parse("quest show " <> quest_id), do: {:show, quest_id}
  def parse("quest info " <> quest_id), do: {:show, quest_id}
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  Questing
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok | {:update, map}
  def run(command, session, state)
  def run({:list, :active}, _session, %{socket: socket, user: user}) do
    case Quest.for(user) do
      [] ->
        socket |> @socket.echo("You have no active quests.")
      quests ->
        socket |> @socket.echo(Format.quest_progress(quests))
    end
    :ok
  end
  def run({:show, quest_id}, _session, %{socket: socket, user: user}) do
    case Quest.progress_for(user, quest_id) do
      nil ->
        socket |> @socket.echo("You have not started this quest.")
      progress ->
        socket |> @socket.echo(Format.quest_detail(progress))
    end
    :ok
  end
end
