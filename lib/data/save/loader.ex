defmodule Data.Save.Loader do
  @moduledoc """
  Functions for loading a save struct
  """

  alias Data.Ability
  alias Data.ActionBar
  alias Data.Item
  alias Data.Save
  alias Data.Save.Migrations

  @doc """
  Load the save map from the database into a `Save` struct
  """
  def load(save) do
    save =
      save
      |> atomize()
      |> atomize_map(:config)
      |> atomize_map(:stats)
      |> atomize_map(:wearing)
      |> atomize_map(:wielding)
      |> Migrations.migrate()
      |> Migrations.migrate_config()
      |> hydrate_items()
      |> hydrate_abilities()
      |> hydrate_actions()

    {:ok, struct(Save, save)}
  end

  @doc """
  Turn keys into atoms
  """
  def atomize(map) do
    Enum.into(map, %{}, fn {key, val} ->
      {String.to_atom(key), val}
    end)
  end

  @doc """
  Take an internal map and atomize the keys

      iex> Loader.atomize_map(%{config: %{"key" => "value"}}, :config)
      %{config: %{key: "value"}}

      iex> Loader.atomize_map(%{config: nil}, :config)
      %{config: %{}}

      iex> Loader.atomize_map(%{}, :config)
      %{}
  """
  def atomize_map(save, key) do
    with {:ok, map} <- Map.fetch(save, key) do
      case is_nil(map) do
        true ->
          Map.put(save, key, %{})

        false ->
          Map.put(save, key, atomize(map))
      end
    else
      _ ->
        save
    end
  end

  @doc """
  Hydrate items and load their instances
  """
  def hydrate_items(save = %{items: items, wearing: wearing, wielding: wielding})
      when is_list(items) do
    items =
      items
      |> Enum.map(&hydrate_item/1)
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

  def hydrate_items(save), do: save

  defp hydrate_item(item) do
    case Item.Instance.load(item) do
      {:ok, instance} ->
        instance

      _ ->
        nil
    end
  end

  @doc """
  Hydrate actions into their structs
  """
  def hydrate_actions(save = %{actions: actions}) when actions != nil do
    actions =
      actions
      |> Enum.map(fn action ->
        for {key, val} <- action, into: %{}, do: {String.to_atom(key), val}
      end)
      |> Enum.map(fn action ->
        case action.type do
          "skill" ->
            struct(ActionBar.SkillAction, action)

          "command" ->
            struct(ActionBar.CommandAction, action)
        end
      end)

    %{save | actions: actions}
  end

  def hydrate_actions(save), do: save

  def hydrate_abilities(save = %{abilities: abilities}) when abilities != nil do
    abilities =
      abilities
      |> Enum.map(fn ability ->
        for {key, val} <- ability, into: %{}, do: {String.to_atom(key), val}
      end)
      |> Enum.map(fn ability ->
        struct(Ability.Instance, ability)
      end)

    %{save | abilities: abilities}
  end

  def hydrate_abilities(save), do: save
end
