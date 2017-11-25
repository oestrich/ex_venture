defmodule Data.Item.Instance do
  @moduledoc """
  An instance of an item
  """

  @behaviour Ecto.Type

  @enforce_keys [:id, :created_at]
  defstruct [:id, :created_at]

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(instance) when is_map(instance), do: {:ok, instance}
  def cast(_), do: :error

  @impl Ecto.Type
  @doc """
  Load an item instance from the database

      iex> Data.Item.Instance.load(%{"id" => 1, "created_at" => "2018"})
      {:ok, %Data.Item.Instance{id: 1, created_at: "2018"}}
  """
  def load(instance = %__MODULE__{}), do: {:ok, instance}
  def load(instance) do
    instance = for {key, val} <- instance, into: %{}, do: {String.to_atom(key), val}
    {:ok, struct(__MODULE__, instance)}
  end

  @impl Ecto.Type
  def dump(instance) when is_map(instance), do: {:ok, Map.delete(instance, :__struct__)}
  def dump(_), do: :error
end
