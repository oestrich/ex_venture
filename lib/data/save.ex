defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  import Data.Type

  alias Data.Item
  alias Data.Stats

  @type t :: %{
    room_id: integer,
    channels: [String.t],
    level: integer,
    experience_points: integer,
    stats: map,
    currency: integer,
    items: [Item.instance()],
    wearing: %{
      chest: integer,
    },
    wielding: %{
      right: integer,
      left: integer,
    },
  }

  defstruct [:room_id, :channels, :level, :experience_points, :stats, :currency, :items, :wearing, :wielding]

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  @doc """
  Load a save from the database

      iex> Data.Save.load(%{"room_id" => 1})
      {:ok, %Data.Save{room_id: 1, channels: [], currency: 0}}

      iex> Data.Save.load(%{"stats" => %{"health" => 50, "strength" => 10, "dexterity" => 10}})
      {:ok, %Data.Save{channels: [], currency: 0, stats: %{health: 50, strength: 10, dexterity: 10}}}

      iex> Data.Save.load(%{"wearing" => %{"chest" => 1}})
      {:ok, %Data.Save{channels: [], currency: 0, wearing: %{chest: 1}}}

      iex> Data.Save.load(%{"wielding" => %{"right" => 1}})
      {:ok, %Data.Save{channels: [], currency: 0, wielding: %{right: 1}}}
  """
  @spec load(save :: map) :: {:ok, Data.Save.t}
  @impl Ecto.Type
  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}

    save = save
    |> ensure(:channels, [])
    |> ensure(:currency, 0)
    |> atomize_stats()
    |> atomize_wearing()
    |> atomize_wielding()

    {:ok, struct(__MODULE__, save)}
  end

  defp ensure(save, field, default) do
    case Map.get(save, field, nil) do
      nil -> Map.put(save, field, default)
      _ -> save
    end
  end

  defp atomize_stats(save = %{stats: stats}) when stats != nil do
    stats = for {key, val} <- stats, into: %{}, do: {String.to_atom(key), val}
    %{save | stats: stats}
  end
  defp atomize_stats(save), do: save

  defp atomize_wearing(save = %{wearing: wearing}) when wearing != nil do
    wearing = for {key, val} <- wearing, into: %{}, do: {String.to_atom(key), val}
    %{save | wearing: wearing}
  end
  defp atomize_wearing(save), do: save

  defp atomize_wielding(save = %{wielding: wielding}) when wielding != nil do
    wielding = for {key, val} <- wielding, into: %{}, do: {String.to_atom(key), val}
    %{save | wielding: wielding}
  end
  defp atomize_wielding(save), do: save

  @impl Ecto.Type
  def dump(save) when is_map(save), do: {:ok, Map.delete(save, :__struct__)}
  def dump(_), do: :error

  @doc """
  Validate a save struct

      iex> Data.Save.valid?(base_save())
      true

      iex> Data.Save.valid?(%Data.Save{room_id: 1, items: [], wearing: %{}, wielding: %{}})
      false

      iex> Data.Save.valid?(%Data.Save{})
      false
  """
  @spec valid?(save :: Save.t) :: boolean
  def valid?(save) do
    keys(save) == [:channels, :currency, :experience_points, :items, :level, :room_id, :stats, :wearing, :wielding]
      && valid_channels?(save)
      && valid_currency?(save)
      && valid_stats?(save)
      && valid_items?(save)
      && valid_room_id?(save)
      && valid_wearing?(save)
      && valid_wielding?(save)
  end

  @doc """
  Validate channels are correct

      iex> Data.Save.valid_channels?(%{channels: ["global"]})
      true

      iex> Data.Save.valid_channels?(%{channels: [:bad]})
      false

      iex> Data.Save.valid_channels?(%{channels: :anything})
      false
  """
  @spec valid_channels?(save :: Save.t) :: boolean
  def valid_channels?(save)
  def valid_channels?(%{channels: channels}) do
    is_list(channels) && Enum.all?(channels, &is_binary/1)
  end

  @doc """
  Validate currency is correct

      iex> Data.Save.valid_currency?(%{currency: 1})
      true

      iex> Data.Save.valid_currency?(%{currency: :anything})
      false
  """
  @spec valid_currency?(save :: Save.t) :: boolean
  def valid_currency?(save)
  def valid_currency?(%{currency: currency}) do
    is_integer(currency)
  end

  @doc """
  Validate stats are correct

      iex> Data.Save.valid_stats?(%{stats: base_stats()})
      true

      iex> Data.Save.valid_stats?(%{stats: :anything})
      false
  """
  @spec valid_stats?(save :: Save.t) :: boolean
  def valid_stats?(save)
  def valid_stats?(%{stats: stats}) do
    is_map(stats) && Stats.valid_character?(stats)
  end

  @doc """
  Validate items is correct

      iex> item = Data.Item.instantiate(%{id: 1})
      iex> Data.Save.valid_items?(%Data.Save{items: [item]})
      true

      iex> item = Data.Item.instantiate(%{id: 1})
      iex> Data.Save.valid_items?(%{items: [item, :anything]})
      false

      iex> Data.Save.valid_items?(%{items: :anything})
      false
  """
  @spec valid_items?(save :: Save.t) :: boolean
  def valid_items?(save)
  def valid_items?(%{items: items}) when is_list(items) do
    items
    |> Enum.all?(fn (instance) ->
      is_map(instance) && instance.__struct__ == Item.Instance
    end)
  end
  def valid_items?(_), do: false

  @doc """
  Validate room_id is correct

      iex> Data.Save.valid_room_id?(%{room_id: 1})
      true

      iex> Data.Save.valid_room_id?(%{room_id: :anything})
      false
  """
  @spec valid_room_id?(save :: Save.t) :: boolean
  def valid_room_id?(save)
  def valid_room_id?(%{room_id: room_id}), do: is_integer(room_id)

  @doc """
  Validate wearing is correct

      iex> Data.Save.valid_wearing?(%{wearing: %{}})
      true

      iex> Data.Save.valid_wearing?(%{wearing: %{chest: 1}})
      true

      iex> Data.Save.valid_wearing?(%{wearing: %{eye: 1}})
      false

      iex> Data.Save.valid_wearing?(%{wearing: %{finger: :anything}})
      false

      iex> Data.Save.valid_wearing?(%{wearing: :anything})
      false
  """
  @spec valid_wearing?(save :: Save.t) :: boolean
  def valid_wearing?(save)
  def valid_wearing?(%{wearing: wearing}) do
    is_map(wearing) && Enum.all?(wearing, fn ({key, val}) -> key in Data.Stats.slots() && is_integer(val) end)
  end

  @doc """
  Validate wielding is correct

      iex> Data.Save.valid_wielding?(%{wielding: %{}})
      true

      iex> Data.Save.valid_wielding?(%{wielding: %{right: 1}})
      true

      iex> Data.Save.valid_wielding?(%{wielding: %{right: :anything}})
      false

      iex> Data.Save.valid_wielding?(%{wielding: :anything})
      false
  """
  @spec valid_wielding?(save :: Save.t) :: boolean
  def valid_wielding?(save)
  def valid_wielding?(%{wielding: wielding}) do
    is_map(wielding) && Enum.all?(wielding, fn ({key, val}) -> key in [:right, :left] && is_integer(val) end)
  end
end
