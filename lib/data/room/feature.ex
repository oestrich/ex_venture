defmodule Data.Room.Feature do
  @moduledoc """
  A feature of a room
  """

  @behaviour Ecto.Type

  defstruct [:id, :key, :short_description, :description]

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(feature) when is_map(feature), do: {:ok, feature}
  def cast(_), do: :error

  @impl Ecto.Type
  @doc """
  Load an item feature from the database

      iex> {:ok, feature} = Data.Room.Feature.load(%{"key" => "log"})
      iex> feature.key
      "log"
  """
  def load(feature = %__MODULE__{}), do: {:ok, feature}

  def load(feature) do
    feature = for {key, val} <- feature, into: %{}, do: {String.to_atom(key), val}
    feature = ensure_id(feature)
    {:ok, struct(__MODULE__, feature)}
  end

  defp ensure_id(feature) do
    case Map.has_key?(feature, :id) do
      true -> feature
      false -> Map.put(feature, :id, UUID.uuid4())
    end
  end

  @impl Ecto.Type
  def dump(feature) when is_map(feature), do: {:ok, Map.delete(feature, :__struct__)}
  def dump(_), do: :error
end
