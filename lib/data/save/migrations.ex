defmodule Data.Save.Migrations do
  @moduledoc """
  Migrate data from one save version to another

  Always in the higher direction
  """

  alias Data.Item
  alias Data.Save.Config
  alias Data.Type

  @doc """
  Migrate an old save forward
  """
  def migrate(save) do
    case Map.has_key?(save, :version) do
      true ->
        migrate_save(save)

      false ->
        save
        |> Map.put(:version, 1)
        |> migrate_save()
    end
  end

  @doc """
  Migrate the save structure forward
  """
  def migrate_save(save = %{version: 13}) do
    save
    |> Map.put(:proficiencies, [])
    |> Map.put(:version, 14)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 12}) do
    # This particular save data should *already* exist, but I am adding the
    # version to delete the ensures from the `Save.Loader`.

    save
    |> Type.ensure(:channels, [])
    |> Type.ensure(:currency, 0)
    |> Type.ensure(:items, [])
    |> Map.put(:version, 13)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 11}) do
    save
    |> Map.put(:actions, [])
    |> Map.put(:version, 12)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 10, stats: stats}) when stats != nil do
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
    |> migrate_save()
  end

  # for the starting save which has empty stats, migrate the version forward
  def migrate_save(save = %{version: 10}) do
    save
    |> Map.put(:version, 11)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 9}) do
    config = Map.put(save.config, :prompt, Config.default_prompt())

    save
    |> Map.put(:config, config)
    |> Map.put(:version, 10)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 8, stats: stats}) when stats != nil do
    stats =
      stats
      |> Map.put(:endurance_points, stats.move_points)
      |> Map.put(:max_endurance_points, stats.max_move_points)
      |> Map.delete(:move_points)
      |> Map.delete(:max_move_points)

    save
    |> Map.put(:stats, stats)
    |> Map.put(:version, 9)
    |> migrate_save()
  end

  # for the starting save which has empty stats, migrate the version forward
  def migrate_save(save = %{version: 8}) do
    save
    |> Map.put(:version, 9)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 7}) do
    save
    |> Map.put(:level_stats, %{})
    |> default_version_stats(7)
    |> Map.put(:version, 8)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 6, stats: stats}) when stats != nil do
    stats =
      stats
      |> Map.put(:health_points, stats.health)
      |> Map.put(:max_health_points, stats.max_health)
      |> Map.delete(:health)
      |> Map.delete(:max_health)

    save
    |> Map.put(:stats, stats)
    |> Map.put(:version, 7)
    |> migrate_save()
  end

  # for the starting save which has empty stats, migrate the version forward
  def migrate_save(save = %{version: 6}) do
    save
    |> Map.put(:version, 7)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 5}) do
    save
    |> Map.put(:config, %{hints: true})
    |> Map.put(:version, 6)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 4}) do
    save
    |> Map.put(:spent_experience_points, 0)
    |> Map.put(:version, 5)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 3}) do
    save
    |> Map.put(:skill_ids, [])
    |> Map.put(:version, 4)
    |> migrate_save()
  end

  def migrate_save(save = %{version: 2}) do
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
    |> migrate_save()
  end

  def migrate_save(save = %{version: 1}) do
    items =
      save
      |> Map.get(:item_ids, [])
      |> Enum.map(&Item.instantiate(%Data.Item{id: &1}))

    save
    |> Map.put(:items, items)
    |> Map.delete(:item_ids)
    |> default_version_stats(1)
    |> Map.put(:version, 2)
    |> migrate_save()
  end

  def migrate_save(save), do: save

  defp default_version_stats(save = %{stats: stats}, 7) when stats != nil do
    stats = Type.ensure(stats, :constitution, 10)
    %{save | stats: stats}
  end

  defp default_version_stats(save = %{stats: stats}, 1) when stats != nil do
    stats =
      stats
      |> Type.ensure(:wisdom, 10)
      |> Type.ensure(:dexterity, 10)
      |> Type.ensure(:health, 10)
      |> Type.ensure(:max_health, 10)
      |> Type.ensure(:move_points, 10)
      |> Type.ensure(:max_move_points, 10)

    %{save | stats: stats}
  end

  defp default_version_stats(save, _version), do: save

  @doc """
  Migrate the user's config to ensure defaults are present
  """
  def migrate_config(save) do
    config =
      save.config
      |> ensure_config(:prompt, Config.default_prompt())
      |> ensure_config(:pager_size, 19)
      |> ensure_config(:regen_notifications, false)

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
end
