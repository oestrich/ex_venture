defmodule Game.Insight do
  @moduledoc """
  Gain insight into certain game features such as bad commands
  """

  use GenServer

  alias Metrics.CommandInstrumenter

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #
  # Client
  #

  @doc """
  Log a bad command
  """
  @spec bad_command(String.t()) :: :ok
  def bad_command(command) do
    GenServer.cast(__MODULE__, {:bad_command, command, Timex.now()})
  end

  @doc """
  Get commands that were logged as bad
  """
  @spec bad_commands() :: [{String.t(), DateTime.t()}]
  def bad_commands() do
    GenServer.call(__MODULE__, :bad_commands)
  end

  #
  # Server
  #

  def init(_) do
    {:ok, %{bad_commands: []}}
  end

  def handle_call(:bad_commands, _from, state = %{bad_commands: bad_commands}) do
    {:reply, bad_commands, state}
  end

  def handle_cast({:bad_command, command, timestamp}, state = %{bad_commands: bad_commands}) do
    CommandInstrumenter.bad_parse()
    {:noreply, Map.put(state, :bad_commands, [{command, timestamp} | bad_commands])}
  end
end
