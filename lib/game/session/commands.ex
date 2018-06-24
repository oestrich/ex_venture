defmodule Game.Session.Commands do
  @moduledoc """
  Module to hold functions related to command processing
  """

  use Networking.Socket

  alias Game.Color
  alias Game.Command
  alias Game.Command.Pager
  alias Game.Session
  alias Game.Session.Regen
  alias Game.Session.State

  @doc """
  Parse and run a command from the user
  """
  @spec process_command(State.t(), String.t()) :: tuple()
  def process_command(state = %{user: user}, message) do
    state = Map.merge(state, %{last_recv: Timex.now()})

    message
    |> Color.delink_commands()
    |> Command.parse(user)
    |> run_command(state)
  end

  @doc """
  Run a command that has been parsed
  """
  @spec run_command(Command.t(), State.t()) :: tuple()
  def run_command(command, state) do
    state = record_command(state, command)

    case command |> Command.run(state) do
      {:update, state} ->
        Session.Registry.update(%{state.user | save: state.save}, state)

        state =
          state
          |> Session.Process.prompt()
          |> Regen.maybe_trigger_regen()
          |> Map.put(:mode, "commands")

        {:noreply, state}

      {:update, state, {command = %Command{}, send_in}} ->
        Session.Registry.update(%{state.user | save: state.save}, state)

        state =
          state
          |> Regen.maybe_trigger_regen()
          |> Map.put(:mode, "continuing")

        :erlang.send_after(send_in, self(), {:continue, command})

        {:noreply, state}

      {:paginate, text, state} ->
        state =
          state
          |> Map.put(:pagination, %{text: text})

        {:noreply, Pager.paginate(state, lines: state.save.config.pager_size)}

      {:editor, module, state} ->
        state =
          state
          |> Map.put(:mode, "editor")
          |> Map.put(:editor_module, module)

        {:noreply, state}

      {:skip, :prompt} ->
        {:noreply, Map.put(state, :mode, "commands")}

      {:skip, :prompt, state} ->
        {:noreply, Map.put(state, :mode, "commands")}

      {:error, :room_offline} ->
        message =
          "{red}ERROR{/red}: {white}The game is experience issues, the room is not online.{/white}"

        state.socket |> @socket.echo(message)
        {:stop, :normal, :state}

      _ ->
        state |> Session.Process.prompt()
        {:noreply, Map.put(state, :mode, "commands")}
    end
  end

  @doc """
  Record a command to run
  """
  @spec record_command(State.t(), Command.t()) :: State.t()
  def record_command(state = %{stats: stats}, command = %Command{}) do
    commands = Map.get(stats, :commands, %{})
    count = Map.get(commands, command.module, 0)
    commands = Map.put(commands, command.module, count + 1)
    %{state | stats: %{commands: commands}}
  end

  def record_command(state, _), do: state
end
