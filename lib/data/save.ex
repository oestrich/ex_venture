defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  import Data.Type

  alias Data.Item
  alias Data.Stats
  alias Data.Save.Config

  @type t :: %{
          room_id: integer,
          channels: [String.t()],
          level: integer,
          level_stats: map(),
          experience_points: integer(),
          spent_experience_points: integer(),
          stats: map,
          currency: integer,
          skill_ids: [integer()],
          items: [Item.instance()],
          config: %{
            hints: boolean(),
            prompt: String.t()
          },
          wearing: %{
            chest: integer
          },
          wielding: %{
            right: integer,
            left: integer
          }
        }

  defstruct [
    :channels,
    :config,
    :currency,
    :experience_points,
    :items,
    :level,
    :level_stats,
    :room_id,
    :skill_ids,
    :spent_experience_points,
    :stats,
    :version,
    :wearing,
    :wielding
  ]

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(save) when is_map(save), do: {:ok, save}
  def cast(_), do: :error

  @doc """
  Load a save from the database
  """
  @spec load(map()) :: {:ok, Data.Save.t()}
  @impl Ecto.Type
  def load(save) do
    save = for {key, val} <- save, into: %{}, do: {String.to_atom(key), val}

    save =
      save
      |> ensure(:channels, [])
      |> ensure(:currency, 0)
      |> ensure(:items, [])
      |> atomize_config()
      |> atomize_stats()
      |> atomize_wearing()
      |> atomize_wielding()
      |> migrate()
      |> migrate_config()
      |> load_items()

    {:ok, struct(__MODULE__, save)}
  end

  defp atomize_config(save = %{config: config}) when config != nil do
    config = for {key, val} <- config, into: %{}, do: {String.to_atom(key), val}
    %{save | config: config}
  end

  defp atomize_config(save), do: save

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

  defp load_items(save = %{items: items, wearing: wearing, wielding: wielding})
       when is_list(items) do
    items =
      items
      |> Enum.map(fn item ->
        case Item.Instance.load(item) do
          {:ok, instance} -> instance
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    wearing =
      for {key, item} <- wearing, into: %{} do
        with {:ok, instance} <- Item.Instance.load(item) do
          {key, instance}
        end
      end

    wielding =
      for {key, item} <- wielding, into: %{} do
        with {:ok, instance} <- Item.Instance.load(item) do
          {key, instance}
        end
      end

    %{save | items: items, wearing: wearing, wielding: wielding}
  end

  defp load_items(save), do: save

  @doc """
  Migrate the user's config to ensure defaults are present
  """
  @spec migrate_config(t()) :: t()
  def migrate_config(save) do
    config =
      save.config
      |> ensure_config(:prompt, Config.default_prompt())
      |> ensure_config(:pager_size, 20)
      |> ensure_config(:regen_notifications, true)

    %{save | config: config}
  end

  defp ensure_config(config, key, default) do
    case Map.get(config, key, nil) do
      nil ->
        Map.put(config, key, default)

      _ ->
        config
    end
  end

  @impl Ecto.Type
  def dump(save) when is_map(save), do: {:ok, Map.delete(save, :__struct__)}
  def dump(_), do: :error

  @doc """
  Migrate an old save
  """
  def migrate(save) do
    case Map.has_key?(save, :version) do
      true ->
        save |> _migrate()

      false ->
        save |> Map.put(:version, 1) |> _migrate()
    end
  end

  defp _migrate(save = %{version: 10, stats: stats}) when stats != nil do
    stats =
      stats
      |> Map.put(:agility, stats.dexterity)
      |> Map.put(:awareness, stats.wisdom)
      |> Map.put(:vitality, stats.constitution)
      |> Map.put(:willpower, stats.constitution)
      |> Map.delete(:constitution)
      |> Map.delete(:dexterity)
      |> Map.delete(:wisdom)

    save
    |> Map.put(:stats, stats)
    |> Map.put(:version, 11)
    |> _migrate()
  end

  # for the starting save which has empty stats, migrate the version forward
  defp _migrate(save = %{version: 10}) do
    save
    |> Map.put(:version, 11)
    |> _migrate()
  end

  defp _migrate(save = %{version: 9}) do
    config = Map.put(save.config, :prompt, Config.default_prompt())

    save
    |> Map.put(:config, config)
    |> Map.put(:version, 10)
    |> _migrate()
  end

  defp _migrate(save = %{version: 8, stats: stats}) when stats != nil do
    stats =
      stats
      |> Map.put(:endurance_points, stats.move_points)
      |> Map.put(:max_endurance_points, stats.max_move_points)
      |> Map.delete(:move_points)
      |> Map.delete(:max_move_points)

    save
    |> Map.put(:stats, stats)
    |> Map.put(:version, 9)
    |> _migrate()
  end

  # for the starting save which has empty stats, migrate the version forward
  defp _migrate(save = %{version: 8}) do
    save
    |> Map.put(:version, 9)
    |> _migrate()
  end

  defp _migrate(save = %{version: 7}) do
    save
    |> Map.put(:level_stats, %{})
    |> Map.put(:version, 8)
    |> _migrate()
  end

  defp _migrate(save = %{version: 6, stats: stats}) when stats != nil do
    stats =
      stats
      |> Map.put(:health_points, stats.health)
      |> Map.put(:max_health_points, stats.max_health)
      |> Map.delete(:health)
      |> Map.delete(:max_health)

    save
    |> Map.put(:stats, stats)
    |> Map.put(:version, 7)
    |> _migrate()
  end

  # for the starting save which has empty stats, migrate the version forward
  defp _migrate(save = %{version: 6}) do
    save
    |> Map.put(:version, 7)
    |> _migrate()
  end

  defp _migrate(save = %{version: 5}) do
    save
    |> Map.put(:config, %{hints: true})
    |> Map.put(:version, 6)
    |> _migrate()
  end

  defp _migrate(save = %{version: 4}) do
    save
    |> Map.put(:spent_experience_points, 0)
    |> Map.put(:version, 5)
    |> _migrate()
  end

  defp _migrate(save = %{version: 3}) do
    save
    |> Map.put(:skill_ids, [])
    |> Map.put(:version, 4)
    |> _migrate()
  end

  defp _migrate(save = %{version: 2}) do
    wielding =
      save
      |> Map.get(:wielding, [])
      |> Enum.reduce(%{}, fn {key, id}, map ->
        item = Item.instantiate(%Data.Item{id: id})
        Map.put(map, key, item)
      end)

    wearing =
      save
      |> Map.get(:wearing, [])
      |> Enum.reduce(%{}, fn {key, id}, map ->
        item = Item.instantiate(%Data.Item{id: id})
        Map.put(map, key, item)
      end)

    save
    |> Map.put(:wielding, wielding)
    |> Map.put(:wearing, wearing)
    |> Map.put(:version, 3)
    |> _migrate()
  end

  defp _migrate(save = %{version: 1}) do
    items =
      save
      |> Map.get(:item_ids, [])
      |> Enum.map(&Item.instantiate(%Data.Item{id: &1}))

    save
    |> Map.put(:items, items)
    |> Map.delete(:item_ids)
    |> Map.put(:version, 2)
    |> _migrate()
  end

  defp _migrate(save), do: save

  @doc """
  Validate a save struct

      iex> Data.Save.valid?(base_save())
      true

      iex> Data.Save.valid?(%Data.Save{room_id: 1, items: [], wearing: %{}, wielding: %{}})
      false

      iex> Data.Save.valid?(%Data.Save{})
      false
  """
  @spec valid?(Save.t()) :: boolean()
  def valid?(save) do
    keys(save) == [
      :channels,
      :config,
      :currency,
      :experience_points,
      :items,
      :level,
      :level_stats,
      :room_id,
      :skill_ids,
      :spent_experience_points,
      :stats,
      :version,
      :wearing,
      :wielding
    ] && valid_channels?(save) && valid_currency?(save) && valid_stats?(save) &&
      valid_items?(save) && valid_room_id?(save) && valid_wearing?(save) && valid_wielding?(save) &&
      valid_config?(save)
  end

  @doc """
  Validate config are correct

      iex> Data.Save.valid_config?(%{config: %{hints: true, prompt: "", pager_size: 20, regen_notifications: true}})
      true

      iex> Data.Save.valid_config?(%{config: %{hints: false, prompt: "Hi", pager_size: 30, regen_notifications: false}})
      true

      iex> Data.Save.valid_config?(%{config: [:bad]})
      false

      iex> Data.Save.valid_config?(%{config: :anything})
      false
  """
  @spec valid_config?(Save.t()) :: boolean()
  def valid_config?(save)

  def valid_config?(%{config: config}) do
    is_map(config) && config_keys(config) == [:hints, :pager_size, :prompt, :regen_notifications] &&
      is_boolean(config.hints) && is_binary(config.prompt) && is_integer(config.pager_size) &&
      is_boolean(config.regen_notifications)
  end

  defp config_keys(config) do
    config
    |> keys()
    |> Enum.reject(fn color ->
      color
      |> to_string()
      |> String.starts_with?("color")
    end)
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
  @spec valid_channels?(Save.t()) :: boolean()
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
  @spec valid_currency?(Save.t()) :: boolean()
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
  @spec valid_stats?(Save.t()) :: boolean()
  def valid_stats?(save)

  def valid_stats?(%{stats: stats}) do
    is_map(stats) && Stats.valid_character?(stats)
  end

  @doc """
  Validate items is correct

      iex> item = Data.Item.instantiate(%{id: 1, is_usable: false})
      iex> Data.Save.valid_items?(%Data.Save{items: [item]})
      true

      iex> item = Data.Item.instantiate(%{id: 1, is_usable: false})
      iex> Data.Save.valid_items?(%{items: [item, :anything]})
      false

      iex> Data.Save.valid_items?(%{items: :anything})
      false
  """
  @spec valid_items?(Save.t()) :: boolean()
  def valid_items?(save)

  def valid_items?(%{items: items}) when is_list(items) do
    items
    |> Enum.all?(fn instance ->
      is_map(instance) && instance.__struct__ == Item.Instance
    end)
  end

  def valid_items?(_), do: false

  @doc """
  Validate room_id is correct

      iex> Data.Save.valid_room_id?(%{room_id: 1})
      true

      iex> Data.Save.valid_room_id?(%{room_id: "overworld:1:1,1"})
      true

      iex> Data.Save.valid_room_id?(%{room_id: "overworld:111"})
      false

      iex> Data.Save.valid_room_id?(%{room_id: :anything})
      false
  """
  @spec valid_room_id?(Save.t()) :: boolean()
  def valid_room_id?(save)
  def valid_room_id?(%{room_id: room_id}) do
    case room_id do
      "overworld:" <> overworld_id ->
        case Game.Overworld.split_id(overworld_id) do
          :error ->
            false

          _ ->
            true
        end

      room_id ->
        is_integer(room_id)
    end
  end

  @doc """
  Validate wearing is correct

      iex> Data.Save.valid_wearing?(%{wearing: %{}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Data.Save.valid_wearing?(%{wearing: %{chest: item}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Data.Save.valid_wearing?(%{wearing: %{eye: item}})
      false

      iex> Data.Save.valid_wearing?(%{wearing: %{finger: :anything}})
      false

      iex> Data.Save.valid_wearing?(%{wearing: :anything})
      false
  """
  @spec valid_wearing?(Save.t()) :: boolean()
  def valid_wearing?(save)

  def valid_wearing?(%{wearing: wearing}) do
    is_map(wearing) &&
      Enum.all?(wearing, fn
        {key, val = %Item.Instance{}} -> key in Stats.slots() && is_integer(val.id)
        _ -> false
      end)
  end

  @doc """
  Validate wielding is correct

      iex> Data.Save.valid_wielding?(%{wielding: %{}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Data.Save.valid_wielding?(%{wielding: %{right: item}})
      true

      iex> Data.Save.valid_wielding?(%{wielding: %{right: :anything}})
      false

      iex> Data.Save.valid_wielding?(%{wielding: :anything})
      false
  """
  @spec valid_wielding?(Save.t()) :: boolean()
  def valid_wielding?(save)

  def valid_wielding?(%{wielding: wielding}) do
    is_map(wielding) &&
      Enum.all?(wielding, fn
        {key, val = %Item.Instance{}} -> key in [:right, :left] && is_integer(val.id)
        _ -> false
      end)
  end
end
