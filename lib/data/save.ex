defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  import Data.Type

  alias Data.Stats

  @type t :: %{
    room_id: integer,
    channels: [String.t],
    level: integer,
    experience_points: integer,
    stats: map,
    item_ids: [integer],
    wearing: %{
      chest: integer,
    },
    wielding: %{
      right: integer,
      left: integer,
    },
  }

  defstruct [:room_id, :channels, :level, :experience_points, :stats, :item_ids, :wearing, :wielding]

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  @doc """
  Load a save from the database

      iex> Data.Save.load(%{"room_id" => 1})
      {:ok, %Data.Save{room_id: 1, channels: []}}

      iex> Data.Save.load(%{"stats" => %{"health" => 50, "strength" => 10, "dexterity" => 10}})
      {:ok, %Data.Save{channels: [], stats: %{health: 50, strength: 10, dexterity: 10}}}

      iex> Data.Save.load(%{"wearing" => %{"chest" => 1}})
      {:ok, %Data.Save{channels: [], wearing: %{chest: 1}}}

      iex> Data.Save.load(%{"wielding" => %{"right" => 1}})
      {:ok, %Data.Save{channels: [], wielding: %{right: 1}}}
  """
  @spec load(save :: map) :: {:ok, Data.Save.t}
  @impl Ecto.Type
  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}

    save = save
    |> ensure_channels()
    |> atomize_stats()
    |> atomize_wearing()
    |> atomize_wielding()

    {:ok, struct(__MODULE__, save)}
  end

  defp ensure_channels(save) do
    case Map.get(save, :channels, nil) do
      nil -> Map.put(save, :channels, [])
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

      iex> stats = %{health: 50, max_health: 50, strength: 10, intelligence: 10, dexterity: 10, skill_points: 10, max_skill_points: 10}
      iex> save = %Data.Save{room_id: 1, channels: [], level: 1, experience_points: 0, item_ids: [], wearing: %{}, wielding: %{}, stats: stats}
      iex> Data.Save.valid?(save)
      true

      iex> Data.Save.valid?(%Data.Save{room_id: 1, item_ids: [], wearing: %{}, wielding: %{}})
      false

      iex> Data.Save.valid?(%Data.Save{})
      false
  """
  @spec valid?(save :: Save.t) :: boolean
  def valid?(save) do
    keys(save) == [:channels, :experience_points, :item_ids, :level, :room_id, :stats, :wearing, :wielding]
      && valid_channels?(save)
      && valid_stats?(save)
      && valid_item_ids?(save)
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
  Validate stats are correct

      iex> stats = %{health: 50, max_health: 50, strength: 10, intelligence: 10, dexterity: 10, skill_points: 10, max_skill_points: 10}
      iex> Data.Save.valid_stats?(%{stats: stats})
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
  Validate item_ids is correct

      iex> Data.Save.valid_item_ids?(%{item_ids: [1]})
      true

      iex> Data.Save.valid_item_ids?(%{item_ids: [1, :anything]})
      false

      iex> Data.Save.valid_item_ids?(%{item_ids: :anything})
      false
  """
  @spec valid_item_ids?(save :: Save.t) :: boolean
  def valid_item_ids?(save)
  def valid_item_ids?(%{item_ids: item_ids}) when is_list(item_ids) do
    item_ids |> Enum.all?(&(is_integer(&1)))
  end
  def valid_item_ids?(_), do: false

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
