defmodule Web.Supervisor do
  @moduledoc """
  Web Supervisor

  Loads the Endpoint and TelnetChannel monitor
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      supervisor(Web.Endpoint, []),
      worker(Web.NPCChannel.Monitor, []),
      worker(Web.TelnetChannel.Monitor, []),
    ]

    supervise(children, strategy: :one_for_one)
  end
end
