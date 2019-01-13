defmodule Game.Format.Listen do
  @moduledoc """
  Listen formatting
  """

  alias Game.Format

  import Game.Format.Context

  def to_room(room) do
    features =
      Enum.reject(room.features, fn feature ->
        is_nil(feature.listen) || feature.listen == ""
      end)

    context()
    |> assign(:room, room.listen)
    |> assign_many(:features, features, &feature_listen/1)
    |> assign_many(:npcs, room.npcs, &npc_listen/1)
    |> Format.template("{white}You can hear:{/white}[\nroom][\nfeatures][\nnpcs]")
  end

  def feature_listen(feature) do
    String.replace(feature.listen, feature.key, "{white}#{feature.key}{/white}")
  end

  def npc_listen(npc) do
    context()
    |> assign(:name, Format.npc_name(npc))
    |> Format.template(npc.extra.status_listen)
  end
end
