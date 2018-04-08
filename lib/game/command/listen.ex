defmodule Game.Command.Listen do
  @moduledoc """
  The "listen" command
  """

  use Game.Command

  commands(["listen"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Listen"
  def help(:short), do: "Listen to your surrounding"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {command}listen{/command}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Listen.parse("listen")
      {}

      iex> Game.Command.Listen.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("listen"), do: {}

  @impl Game.Command
  def run(command, state)

  def run({}, state = %{save: save}) do
    room = @room.look(save.room_id)

    case room_has_noises?(room) do
      true ->
        state.socket |> @socket.echo(Format.listen_room(room))

      false ->
        state.socket |> @socket.echo("Nothing can be heard")
    end
  end

  defp room_has_noises?(room) do
    !is_nil(room.listen) || Enum.any?(room.features, &(!is_nil(&1.listen)))
  end
end
