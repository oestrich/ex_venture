defmodule Game.Command.Typo do
  @moduledoc """
  The "typo" command
  """

  use Game.Command
  use Game.Command.Editor

  alias Data.Typo
  alias Data.Repo

  commands(["typo"])

  @impl Game.Command
  def help(:topic), do: "Typo"
  def help(:short), do: "Report a typo"

  def help(:full) do
    """
    Report a typo you encounter to the game admins. After entering a title you will
    be able to enter in multi line text for further information.

    Example:
    [ ] > {white}typo title{/white}
    """
  end

  @impl Game.Command
  def run(command, state)

  def run({}, %{socket: socket}) do
    socket
    |> @socket.echo(
      "Please provide a typo title. See {white}help typo{/white} for more information."
    )

    :ok
  end

  def run({typo_title}, state = %{socket: socket}) do
    socket
    |> @socket.echo(
      "Please enter in any more information you have (an empty new line will finish entering text): "
    )

    commands =
      state
      |> Map.get(:commands, %{})
      |> Map.put(:typo, %{title: typo_title, lines: []})

    {:editor, __MODULE__, Map.put(state, :commands, commands)}
  end

  @impl Game.Command.Editor
  def editor({:text, line}, state) do
    typo = Map.get(state.commands, :typo, %{})
    lines = Map.get(typo, :lines) ++ [line]
    typo = Map.put(typo, :lines, lines)
    state = %{state | commands: %{state.commands | typo: typo}}
    {:update, state}
  end

  def editor(:complete, state = %{socket: socket}) do
    typo = state.commands.typo

    params = %{
      title: typo.title,
      body: typo.lines |> Enum.join("\n"),
      reporter_id: state.user.id,
      room_id: state.save.room_id
    }

    params |> create_typo(socket)

    commands =
      state
      |> Map.get(:commands)
      |> Map.delete(:typo)

    {:update, Map.put(state, :commands, commands)}
  end

  defp create_typo(params, socket) do
    changeset = %Typo{} |> Typo.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, _typo} ->
        socket |> @socket.echo("Your typo has been submitted. Thanks!")

      {:error, changeset} ->
        error =
          Enum.map(changeset.errors, fn {field, error} ->
            human_error = Web.ErrorHelpers.translate_error(error)
            "#{field} #{human_error}"
          end)

        socket |> @socket.echo("There was an issue creating the typo.\n#{error}")
    end
  end
end
