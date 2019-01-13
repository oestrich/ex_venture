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
    be able to enter in multi line text for further information. Finalize the typo
    with a blank line.

    Example:
    [ ] > {command}typo title{/command}
    """
  end

  @impl Game.Command
  def run(command, state)

  def run({}, state) do
    message =
      gettext(
        "Please provide a typo title. See {command}help typo{/command} for more information."
      )

    state |> Socket.echo(message)
  end

  def run({typo_title}, state) do
    message =
      gettext(
        "Please enter in any more information you have (an empty new line will finish entering text): "
      )

    state |> Socket.echo(message)

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

  def editor(:complete, state) do
    typo = state.commands.typo

    params = %{
      title: typo.title,
      body: typo.lines |> Enum.join("\n"),
      reporter_id: state.character.id,
      room_id: state.save.room_id
    }

    params |> create_typo(state)

    commands =
      state
      |> Map.get(:commands)
      |> Map.delete(:typo)

    {:update, Map.put(state, :commands, commands)}
  end

  defp create_typo(params, state) do
    changeset = %Typo{} |> Typo.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, _typo} ->
        state |> Socket.echo(gettext("Your typo has been submitted. Thanks!"))

      {:error, changeset} ->
        error =
          Enum.map(changeset.errors, fn {field, error} ->
            human_error = Web.ErrorHelpers.translate_error(error)
            "#{field} #{human_error}"
          end)

        message = gettext("There was an issue creating the typo.")
        state |> Socket.echo("#{message}\n#{error}")
    end
  end
end
