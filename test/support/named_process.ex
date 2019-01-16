defmodule Test.NamedProcess do
  @moduledoc """
  Register a globaly named process that fakes out a normally real process.

  Any messages this process receives will forward them to the test process via `send`.
  """

  use GenServer

  @doc """
  Link a new process to the test process

  This takes place outside of the supervision tree, so the process does
  not hang around.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, [caller: self(), name: name], [name: {:global, name}])
  end

  @impl true
  def init(state) do
    {:ok, Enum.into(state, %{})}
  end

  @impl true
  def handle_cast(message, state) do
    send(state.caller, {state.name, {:cast, message}})
    {:noreply, state}
  end
end
