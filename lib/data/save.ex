defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  @type t :: %{
    room_id: integer,
    class: atom,
    item_ids: [integer],
    wielding: %{
      right: integer,
      left: integer,
    },
  }

  defstruct [:room_id, :class, :item_ids, :wielding]

  @behaviour Ecto.Type

  def type, do: :map

  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}
    save = atomize_class(save)
    save = atomize_wielding(save)
    {:ok, struct(__MODULE__, save)}
  end

  defp atomize_class(save = %{class: class}) do
    %{save | class: String.to_atom(class)}
  end
  defp atomize_class(save), do: save

  defp atomize_wielding(save = %{wielding: wielding}) when wielding != nil do
    wielding = for {key, val} <- wielding, into: %{}, do: {String.to_atom(key), val}
    %{save | wielding: wielding}
  end
  defp atomize_wielding(save), do: save

  def dump(save) when is_map(save), do: {:ok, Map.delete(save, :__struct__)}
  def dump(_), do: :error
end
