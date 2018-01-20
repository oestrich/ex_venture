defmodule Web.NPC do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Conversation
  alias Data.Event
  alias Data.NPC
  alias Data.NPCItem
  alias Data.NPCSpawner
  alias Data.Stats
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  Get all npcs
  """
  @spec all(filter :: map) :: [NPC.t]
  def all(opts \\ []) do
    NPC
    |> order_by([n], n.id)
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(Enum.into(opts, %{}))
  end

  @impl Filter
  def filter_on_attribute({"tag", value}, query) do
    query
    |> where([n], fragment("? @> ?::varchar[]", n.tags, [^value]))
  end
  def filter_on_attribute({"zone_id", value}, query) do
    query
    |> join(:left, [n], ns in assoc(n, :npc_spawners))
    |> where([n, ns], ns.zone_id == ^value)
    |> group_by([n, ns], n.id)
  end
  def filter_on_attribute(_, query), do: query

  @doc """
  List out all npcs for a select box
  """
  @spec for_select() :: [{String.t, integer()}]
  def for_select() do
    NPC
    |> select([n], [n.name, n.id])
    |> order_by([n], n.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  List out all npcs for a select box, that are quest givers
  """
  @spec for_quest_select() :: [{String.t, integer()}]
  def for_quest_select() do
    NPC
    |> select([n], [n.name, n.id])
    |> where([n], n.is_quest_giver == true)
    |> order_by([n], n.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a npc
  """
  @spec get(id :: integer) :: [NPC.t]
  def get(id) do
    NPC
    |> where([c], c.id == ^id)
    |> preload([npc_items: [:item], npc_spawners: [:zone, :room]])
    |> Repo.one
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %NPC{} |> NPC.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(npc :: NPC.t) :: changeset :: map
  def edit(npc), do: npc |> NPC.changeset(%{})

  @doc """
  Create a npc
  """
  @spec create(params :: map) :: {:ok, NPC.t} | {:error, changeset :: map}
  def create(params) do
    %NPC{}
    |> NPC.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a NPC
  """
  @spec update(id :: integer, params :: map) :: {:ok, NPC.t} | {:error, changeset :: map}
  def update(id, params) do
    changeset = id |> get() |> NPC.changeset(cast_params(params))
    case changeset |> Repo.update do
      {:ok, npc} ->
        push_update(npc)
        {:ok, npc}
      anything -> anything
    end
  end

  defp push_update(npc) do
    npc = npc |> Repo.preload([:npc_spawners])
    Enum.map(npc.npc_spawners, fn (npc_spawner) ->
      npc_spawner =
        NPCSpawner
        |> where([ns], ns.id == ^npc_spawner.id)
        |> preload([npc: [:npc_items]])
        |> Repo.one()

      Game.NPC.update(npc_spawner.id, npc_spawner)
    end)
  end

  @doc """
  Cast params into what `Data.NPC` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_stats()
    |> parse_events()
    |> parse_conversations()
    |> parse_tags()
  end

  defp parse_stats(params = %{"stats" => stats}) do
    case Poison.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end
  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load do
      {:ok, stats} ->
        Map.put(params, "stats", stats)
        _ -> params
    end
  end

  defp parse_events(params = %{"events" => events}) do
    case Poison.decode(events) do
      {:ok, events} -> events |> cast_events(params)
      _ -> params
    end
  end
  defp parse_events(params), do: params

  defp cast_events(events, params) do
    events =
      events
      |> Enum.map(fn (event) ->
        case Event.load(event) do
          {:ok, event} -> event
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Map.put(params, "events", events)
  end

  defp parse_conversations(params = %{"conversations" => conversations}) do
    case Poison.decode(conversations) do
      {:ok, conversations} -> conversations |> cast_conversations(params)
      _ -> params
    end
  end
  defp parse_conversations(params), do: params

  defp cast_conversations(conversations, params) do
    conversations =
      conversations
      |> Enum.map(fn (conversation) ->
        case Conversation.load(conversation) do
          {:ok, conversation} -> conversation
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Map.put(params, "conversations", conversations)
  end

  def parse_tags(params = %{"tags" => tags}) do
    tags =
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    params
    |> Map.put("tags", tags)
  end
  def parse_tags(params), do: params

  #
  # Zone NPC
  #

  @doc """
  Load a npc spawner
  """
  @spec get_spawner(id :: integer) :: NPCSpawner.t
  def get_spawner(npc_spawner_id) do
    NPCSpawner
    |> Repo.get(npc_spawner_id)
    |> Repo.preload([:npc, :zone, :room])
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new_spawner(npc :: NPC.t) :: changeset :: map
  def new_spawner(npc) do
    npc
    |> Ecto.build_assoc(:npc_spawners)
    |> NPCSpawner.changeset(%{})
  end

  @doc """
  Get a changeset for an edit page
  """
  @spec edit_spawner(npc_spawner :: NPCSpawner.t) :: changeset :: map
  def edit_spawner(npc_spawner), do: npc_spawner |> NPCSpawner.changeset(%{})

  @doc """
  Add a new NPC spawner
  """
  def add_spawner(npc_id, params) do
    changeset = npc_id |> Ecto.build_assoc(:npc_spawners) |> NPCSpawner.changeset(params)
    case changeset |> Repo.insert() do
      {:ok, npc_spawner} ->
        npc_spawner = npc_spawner |> Repo.preload([:npc])
        Game.Zone.spawn_npc(npc_spawner.zone_id, npc_spawner)
        {:ok, npc_spawner}
      anything -> anything
    end
  end

  @doc """
  Update a NPC Spawner
  """
  @spec update_spawner(id :: integer, params :: map) :: {:ok, NPCSpawner.t} | {:error, changeset :: map}
  def update_spawner(id, params) do
    changeset = id |> get_spawner() |> NPCSpawner.update_changeset(params)
    case changeset |> Repo.update do
      {:ok, npc_spawner} ->
        npc_spawner = npc_spawner |> Repo.preload([npc: [:npc_items]])
        Game.NPC.update(npc_spawner.id, npc_spawner)
        {:ok, npc_spawner}
      anything -> anything
    end
  end

  @doc """
  Delete a room exit
  """
  @spec delete_spawner(npc_spawner_id :: integer) :: {:ok, NPCSpawner.t} | {:error, changeset :: map}
  def delete_spawner(npc_spawner_id) do
    npc_spawner = npc_spawner_id |> get_spawner()
    case npc_spawner |> Repo.delete() do
      {:ok, npc_spawner} ->
        Game.NPC.terminate(npc_spawner.id)
        {:ok, npc_spawner}
      anything -> anything
    end
  end

  #
  # Items
  #

  @doc """
  Get an NPC Item
  """
  @spec get_item(integer()) :: NPCItem.t()
  def get_item(id) do
    NPCItem |> Repo.get(id)
  end

  @doc """
  Get a changeset for a new npc item
  """
  @spec new_item(NPC.t()) :: Ecto.Changeset.t()
  def new_item(npc) do
    npc
    |> Ecto.build_assoc(:npc_items)
    |> NPCItem.changeset(%{})
  end

  @doc """
  Get a changeset for editing a shop item
  """
  @spec edit_item(NPCItem.t()) :: map()
  def edit_item(npc_item) do
    npc_item |> NPCItem.changeset(%{})
  end

  @doc """
  Add an Item to an NPC
  """
  @spec add_item(NPC.t(), map()) :: {:ok, NPC.t()} | {:error, map()}
  def add_item(npc, params) do
    changeset =
      npc
      |> Ecto.build_assoc(:npc_items)
      |> NPCItem.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, npc_item} ->
        push_update(npc)
        {:ok, npc_item}
      anything -> anything
    end
  end

  @doc """
  Update an item on an npc
  """
  @spec update_item(integer(), map) :: {:ok, NPCItem.t()}
  def update_item(id, params) do
    npc_item = id |> get_item()
    changeset = npc_item |> NPCItem.update_changeset(params)

    case changeset |> Repo.update() do
      {:ok, npc_item} ->
        npc = npc_item.npc_id |> get()
        push_update(npc)
        {:ok, npc_item}
      anything -> anything
    end
  end

  @doc """
  Delete an Item from an NPC
  """
  @spec delete_item(integer()) :: {:ok, NPCItem.t()} | {:error, changeset :: map}
  def delete_item(item_id) do
    npc_item = item_id |> get_item()
    case npc_item |> Repo.delete() do
      {:ok, npc_item} ->
        npc = npc_item.npc_id |> get()
        push_update(npc)
        {:ok, npc_item}
      anything -> anything
    end
  end
end
