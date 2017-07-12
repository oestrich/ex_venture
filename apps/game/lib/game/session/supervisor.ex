defmodule Game.Session.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(pid) do
    child_spec = worker(Game.Session, [pid], [id: pid])
    Supervisor.start_child(__MODULE__, child_spec)
  end

  def init(_) do
    children = []
    supervise(children, strategy: :one_for_one)
  end
end
