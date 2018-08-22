defmodule Game.Format.Resources do
  @moduledoc """
  Format a string to include in game resources

  E.g. `[[room:11]]` will be replaced with `{room}Town Center{/room}`
  """

  alias Game.Format
  alias Game.Items
  alias Game.NPC
  alias Game.Room
  alias Game.Zone

  @resource_regex ~r/\[\[(?<resource>\w+):(?<id>\d+)\]\]/

  @doc """
  Parse a string for game resources
  """
  def parse(string) do
    @resource_regex
    |> Regex.split(string, include_captures: true)
    |> _parse()
    |> Enum.join()
  end

  defp _parse([]) do
    []
  end

  defp _parse([piece | pieces]) do
    [format(piece) | _parse(pieces)]
  end

  defp format("[[item:" <> id) do
    id = id_to_integer(id)

    case Items.get(id) do
      {:ok, item} ->
        Format.item_name(item)

      _ ->
        "{error}unknown{/error}"
    end
  end

  defp format("[[npc:" <> id) do
    id = id_to_integer(id)

    case NPC.name(id) do
      {:ok, npc} ->
        Format.npc_name(npc)

      {:error, :offline} ->
        "{error}unknown{/error}"
    end
  end

  defp format("[[room:" <> id) do
    id = id_to_integer(id)

    case Room.name(id) do
      {:ok, room} ->
        Format.room_name(room)

      {:error, :room_offline} ->
        "{error}unknown{/error}"
    end
  end

  defp format("[[zone:" <> id) do
    id = id_to_integer(id)

    case Zone.name(id) do
      {:ok, zone} ->
        Format.zone_name(zone)

      {:error, :offline} ->
        "{error}unknown{/error}"
    end
  end

  defp format("[[" <> _) do
    "{error}unknown{/error}"
  end

  defp format(string), do: string

  defp id_to_integer(id) do
    id
    |> String.replace("]]", "")
    |> String.to_integer()
  end
end
