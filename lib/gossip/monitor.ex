defmodule Gossip.Monitor do
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
    :timer.send_interval(@sweep_delay, :check_socket_alive)
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
    case state.online do
      false ->
        Gossip.start_socket()
        {:noreply, state}

      true ->
        {:noreply, state}
    end
  end

  def handle_info(:check_socket_alive, state) do
    case Process.whereis(Gossip.Socket) do
      nil ->
        Gossip.start_socket()
        {:noreply, state}

      _pid ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    case state.process == pid do
      true ->
        state =
          state
          |> Map.put(:online, false)
          |> Map.put(:process, nil)

        :erlang.send_after(@restart_delay, self(), :restart_socket)

        {:noreply, state}

      false ->
        {:noreply, state}
    end
  end
end
