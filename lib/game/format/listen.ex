defmodule Game.Format.Listen do
  @moduledoc """
  Listen formatting
  """

  alias Game.Format

  import Game.Format.Context

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
      |> Enum.reject(&(is_nil(&1.extra.status_listen) || &1.extra.status_listen == ""))
      |> Enum.map(fn npc ->
        context()
        |> assign(:name, Format.npc_name(npc))
        |> Format.template(npc.extra.status_listen)
      end)

    context()
    |> assign(:room, room.listen)
    |> assign(:features, features)
    |> assign(:npcs, npcs)
    |> Format.template("{white}You can hear:{/white}[\nroom][\nfeatures][\nnpcs]")
    |> Format.wrap()
  end
end
