defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  @type t :: %{
    room_id: integer,
    class: atom,
    item_ids: [integer],
  }

  defstruct [:room_id, :class, :item_ids]

  @behaviour Ecto.Type

  def type, do: :map

  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}
    save = atomize_class(save)
    {:ok, struct(__MODULE__, save)}
  end

  defp atomize_class(save = %{class: class}) do
    %{save | class: String.to_atom(class)}
  end
  defp atomize_class(save), do: save

  def dump(save) when is_map(save), do: {:ok, Map.delete(save, :__struct__)}
  def dump(_), do: :error
end
