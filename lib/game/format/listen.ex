defmodule Game.Format.Listen do
  @moduledoc """
  Listen formatting
  """

  alias Game.Format

  def to_room(room) do
    features =
      room.features
      |> Enum.reject(&(is_nil(&1.listen) || &1.listen == ""))
      |> Enum.map(fn feature ->
        feature.listen
        |> String.replace(feature.key, "{white}#{feature.key}{/white}")
      end)

    npcs =
      room.npcs
      |> Enum.reject(&(is_nil(&1.status_listen) || &1.status_listen == ""))
      |> Enum.map(fn npc ->
        npc.status_listen |> Format.template(%{name: Format.npc_name(npc)})
      end)

    "{white}You can hear:{/white}[\nroom][\nfeatures][\nnpcs]"
    |> Format.template(%{room: room.listen, features: features, npcs: npcs})
    |> Format.wrap()
  end
end
