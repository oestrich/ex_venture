defmodule Game.Command.Bug do
  @moduledoc """
  The "bug" command
  """

  use Game.Command
  use Game.Command.Editor

  alias Data.Bug
  alias Data.Repo

  commands(["bug"])

  @impl Game.Command
  def help(:topic), do: "Bug"
  def help(:short), do: "Report a bug"

  def help(:full) do
    """
    Report a bug you encounter to the game admins. After entering a title you will
    be able to enter in multi line text for further information.

    Example:
    [ ] > {white}bug title{/white}
    """
  end

  @impl Game.Command
  def run(command, state)

  def run({bug_title}, state = %{socket: socket}) do
    socket
    |> @socket.echo(
      "Please enter in any more information you have (an empty new line will finish entering text): "
    )

    commands =
      state
      |> Map.get(:commands, %{})
      |> Map.put(:bug, %{title: bug_title, lines: []})

    {:editor, __MODULE__, Map.put(state, :commands, commands)}
  end

  @impl Game.Command.Editor
  def editor({:text, line}, state) do
    bug = Map.get(state.commands, :bug, %{})
    lines = Map.get(bug, :lines) ++ [line]
    bug = Map.put(bug, :lines, lines)
    state = %{state | commands: %{state.commands | bug: bug}}
    {:update, state}
  end

  def editor(:complete, state = %{socket: socket}) do
    bug = state.commands.bug

    params = %{
      title: bug.title,
      body: bug.lines |> Enum.join("\n"),
      reporter_id: state.user.id
    }

    params |> create_bug(socket)

    commands =
      state
      |> Map.get(:commands)
      |> Map.delete(:bug)

    {:update, Map.put(state, :commands, commands)}
  end

  defp create_bug(params, socket) do
    changeset = %Bug{} |> Bug.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, _bug} ->
        socket |> @socket.echo("Your bug has been submitted. Thanks!")

      {:error, changeset} ->
        error =
          Enum.map(changeset.errors, fn {field, error} ->
            human_error = Web.ErrorHelpers.translate_error(error)
            "#{field} #{human_error}"
          end)

        socket |> @socket.echo("There was an issue creating the bug.\n#{error}")
    end
  end
end
