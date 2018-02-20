defmodule Networking.Supervisor do
  @moduledoc """
  Networking Supervisor

  Sets up the ranch listeners
  """
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Networking.Listener, []),
      worker(Networking.SSLListener, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
