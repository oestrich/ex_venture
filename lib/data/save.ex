defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  @type t :: %{
    room_id: integer,
  }

  defstruct [:room_id]

  @behaviour Ecto.Type

  def type, do: :map

  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}
    {:ok, struct(__MODULE__, save)}
  end

  def dump(save) when is_map(save), do: {:ok, Map.delete(save, :__struct__)}
  def dump(_), do: :error
end
