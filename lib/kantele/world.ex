defmodule Kantele.World do
  @moduledoc """
  GenServer to load and boot the world
  """

  use Supervisor

  alias Kantele.World.Loader
  alias Kantele.World.ZoneCache

  defstruct characters: [], items: [], rooms: [], zones: []

  @doc """
  Dereference a world variable reference
  """
  def dereference(reference) when is_binary(reference) do
    dereference(String.split(reference, "."))
  end

  def dereference([zone_id | reference]) do
    case ZoneCache.get(zone_id) do
      {:ok, zone} ->
        Loader.dereference(zone, reference)

      _ ->
        :error
    end
  end

  @doc false
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  @impl true
  def init(_opts) do
    config = Application.get_env(:kantele, :world, [])
    kickoff = Keyword.get(config, :kickoff, true)

    children = [
      {ZoneCache, [id: ZoneCache, name: ZoneCache]},
      {Kantele.World.Items, [id: Kantele.World.Items, name: Kantele.World.Items]},
      {Kalevala.World, [name: Kantele.World]},
      {Kantele.World.Kickoff, [name: Kantele.World.Kickoff, start: kickoff]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
