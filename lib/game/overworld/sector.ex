defmodule Game.Overworld.Sector do
  @moduledoc """
  Sector process

  For information on the callbacks, see `Game.Environment`
  """

  use GenServer

  alias Game.Environment
  alias Game.NPC
  alias Game.Overworld
  alias Game.Session
  alias Game.Overworld.Sector.Implementation
  alias Metrics.CommunicationInstrumenter

  def start_link(zone_id, sector) do
    GenServer.start_link(__MODULE__, [zone_id, sector], name: pid(zone_id, sector))
  end

  @doc """
  Tuple for the sector, treated as a pid
  """
  def pid(zone_id, sector) do
    {:global, {Game.Overworld.Sector, zone_id, sector}}
  end

  def init([zone_id, sector]) do
    state = %{
      zone_id: zone_id,
      sector: sector,
      players: [],
      npcs: []
    }

    {:ok, state}
  end

  def handle_call({:look, overworld_id}, _from, state) do
    {reply, state} = Implementation.look(state, overworld_id)
    {:reply, reply, state}
  end

  # leaving error for now
  def handle_call({:pick_up, _overworld_id, _item}, _from, state) do
    {:reply, :error, state}
  end

  # leaving error for now
  def handle_call({:pick_up_currency, _overworld_id}, _from, state) do
    {:reply, :error, state}
  end

  def handle_cast({:enter, overworld_id, character, reason}, state) do
    {:noreply, Implementation.character_enter(state, overworld_id, character, reason)}
  end

  def handle_cast({:leave, overworld_id, character, reason}, state) do
    {:noreply, Implementation.character_leave(state, overworld_id, character, reason)}
  end

  def handle_cast({:notify, overworld_id, character, event}, state) do
    {:noreply, Implementation.notify(state, overworld_id, character, event)}
  end

  def handle_cast({:say, overworld_id, sender, message}, state) do
    CommunicationInstrumenter.say()
    handle_cast({:notify, overworld_id, sender, {"room/heard", message}}, state)
  end

  def handle_cast({:emote, overworld_id, sender, message}, state) do
    CommunicationInstrumenter.emote()
    handle_cast({:notify, overworld_id, sender, {"room/heard", message}}, state)
  end

  # skipping for now
  def handle_cast({:drop, _overworld_id, _who, _item}, state) do
    {:noreply, state}
  end

  # skipping for now
  def handle_cast({:drop_currency, _overworld_id, _who, _currency}, state) do
    {:noreply, state}
  end

  def handle_cast({:update_character, overworld_id, character}, state) do
    {:noreply, Implementation.update_character(state, overworld_id, character)}
  end

  defmodule Implementation do
    @moduledoc """
    Implementation for the sector process
    """

    @key :zones

    def look(state, overworld_id) do
      {_zone_id, cell} = Overworld.split_id(overworld_id)

      {:ok, zone} = Cachex.get(@key, state.zone_id)

      characters = filter_characters_to_cell(state, cell)

      environment = %Environment.State.Overworld{
        id: "overworld:" <> overworld_id,
        zone_id: state.zone_id,
        zone: zone.name,
        x: cell.x,
        y: cell.y,
        # eventually from the editor
        ecology: "default",
        exits: Overworld.exits(zone, cell),
        players: characters.players,
        npcs: characters.npcs
      }

      {{:ok, environment}, state}
    end

    def character_enter(state, overworld_id, character, reason) do
      {_zone, cell} = Overworld.split_id(overworld_id)

      state.players |> inform_players(cell, {"room/entered", {character, reason}})
      state.npcs |> inform_npcs(cell, {"room/entered", {character, reason}})

      case character do
        {:player, player} ->
          Map.put(state, :players, [{cell, player} | state.players])

        {:npc, npc} ->
          Map.put(state, :npcs, [{cell, npc} | state.npcs])
      end
    end

    def character_leave(state, overworld_id, character, reason) do
      {_zone, cell} = Overworld.split_id(overworld_id)

      state = filter_character(state, cell, character)

      state.players |> inform_players(cell, {"room/leave", {character, reason}})
      state.npcs |> inform_npcs(cell, {"room/leave", {character, reason}})

      state
    end

    def notify(state, overworld_id, character, event) do
      {_zone, cell} = Overworld.split_id(overworld_id)

      temp_state = filter_character(state, cell, character)
      temp_state.players |> inform_players(cell, event)
      temp_state.npcs |> inform_npcs(cell, event)

      state
    end

    def update_character(state, overworld_id, character) do
      {_zone, cell} = Overworld.split_id(overworld_id)

      state = filter_character(state, cell, character)

      case character do
        {:player, player} ->
          Map.put(state, :players, [{cell, player} | state.players])

        {:npc, npc} ->
          Map.put(state, :npcs, [{cell, npc} | state.npcs])
      end
    end

    defp filter_characters_to_cell(state, cell) do
      players =
        state.players
        |> Enum.filter(fn {player_cell, _player} ->
          cell == player_cell
        end)
        |> Enum.map(&elem(&1, 1))

      npcs =
        state.npcs
        |> Enum.filter(fn {npc_cell, _npc} ->
          cell == npc_cell
        end)
        |> Enum.map(&elem(&1, 1))

      %{players: players, npcs: npcs}
    end

    defp filter_character(state, cell, character) do
      case character do
        {:player, player} ->
          players =
            state.players
            |> Enum.reject(fn {existing_cell, existing_player} ->
              existing_cell == cell && existing_player.id == player.id
            end)

          Map.put(state, :players, players)

        {:npc, npc} ->
          npcs =
            state.npcs
            |> Enum.reject(fn {existing_cell, existing_npc} ->
              existing_cell == cell && existing_npc.id == npc.id
            end)

          Map.put(state, :npcs, npcs)
      end
    end

    defp inform_players(players, cell, action) do
      players
      |> Enum.filter(fn {player_cell, _npc} ->
        cell == player_cell
      end)
      |> Enum.each(fn {_cell, player} ->
        Session.notify(player, action)
      end)
    end

    defp inform_npcs(npcs, cell, action) do
      npcs
      |> Enum.filter(fn {npc_cell, _npc} ->
        cell == npc_cell
      end)
      |> Enum.each(fn {_cell, npc} ->
        NPC.notify(npc.id, action)
      end)
    end
  end
end
