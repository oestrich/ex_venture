defmodule Gossip.Monitor do
  @moduledoc """
  A side process to monitor and restart the websocket for Gossip
  """

  use GenServer, restart: :permanent

  @restart_delay 15_000
  @sweep_delay 30_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def monitor() do
    GenServer.cast(__MODULE__, {:monitor, self()})
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    Process.send_after(self(), :check_socket_alive, @sweep_delay)
    {:ok, %{process: nil, online: false}}
  end

  def handle_cast({:monitor, pid}, state) do
    Process.link(pid)

    state =
      state
      |> Map.put(:online, true)
      |> Map.put(:process, pid)

    {:noreply, state}
  end

  def handle_info(:restart_socket, state) do
    Gossip.start_socket()
    {:noreply, state}
  end

  def handle_info(:check_socket_alive, state) do
    Gossip.start_socket()
    Process.send_after(self(), :check_socket_alive, @sweep_delay)
    {:noreply, state}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case state.process == pid do
      true ->
        state =
          state
          |> Map.put(:online, false)
          |> Map.put(:process, nil)

        Process.send_after(self(), :restart_socket, @restart_delay)

        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end
end
