defmodule Data.Zone.MapCell do
  @moduledoc """
  Overworld map cell
  """

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(cell) when is_map(cell), do: {:ok, cell}
  def cast(_), do: :error

  @doc """
  Load a cell from a stored map
  """
  @impl Ecto.Type
  def load(cell) do
    cell = for {key, val} <- cell, into: %{}, do: {String.to_atom(key), val}
    {:ok, cell}
  end

  @impl Ecto.Type
  def dump(cell) when is_map(cell), do: {:ok, Map.delete(cell, :__struct__)}
  def dump(_), do: :error
end
