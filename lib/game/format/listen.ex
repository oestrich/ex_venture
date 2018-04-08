defmodule Game.Format.Listen do
  @moduledoc """
  Listen formatting
  """

  alias Game.Format

  def to_room(room) do
    features =
      room.features
      |> Enum.map(& &1.listen)
      |> Enum.reject(&(is_nil(&1) || &1 == ""))

    "{white}You can hear:{/white}[\nroom][\nfeatures]"
    |> Format.template(%{room: room.listen, features: features})
    |> Format.wrap()
  end
end
