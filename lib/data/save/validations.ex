defmodule Data.Save.Validations do
  @moduledoc """
  Save validations
  """

  import Data.Type, only: [keys: 1]

  alias Data.Item
  alias Data.Stats

  @doc """
  Validate a save struct

      iex> Validations.valid?(base_save())
      true

      iex> Validations.valid?(%Save{room_id: 1, items: [], wearing: %{}, wielding: %{}})
      false

      iex> Validations.valid?(%Save{})
      false
  """
  def valid?(save) do
    keys(save) == [
      :abilities,
      :actions,
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

      iex> Validations.valid_config?(%{config: %{hints: true, prompt: "", pager_size: 20, regen_notifications: true}})
      true

      iex> Validations.valid_config?(%{config: %{hints: false, prompt: "Hi", pager_size: 30, regen_notifications: false}})
      true

      iex> Validations.valid_config?(%{config: [:bad]})
      false

      iex> Validations.valid_config?(%{config: :anything})
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

      iex> Validations.valid_channels?(%{channels: ["global"]})
      true

      iex> Validations.valid_channels?(%{channels: [:bad]})
      false

      iex> Validations.valid_channels?(%{channels: :anything})
      false
  """
  @spec valid_channels?(Save.t()) :: boolean()
  def valid_channels?(save)

  def valid_channels?(%{channels: channels}) do
    is_list(channels) && Enum.all?(channels, &is_binary/1)
  end

  @doc """
  Validate currency is correct

      iex> Validations.valid_currency?(%{currency: 1})
      true

      iex> Validations.valid_currency?(%{currency: :anything})
      false
  """
  @spec valid_currency?(Save.t()) :: boolean()
  def valid_currency?(save)

  def valid_currency?(%{currency: currency}) do
    is_integer(currency)
  end

  @doc """
  Validate stats are correct

      iex> Validations.valid_stats?(%{stats: base_stats()})
      true

      iex> Validations.valid_stats?(%{stats: :anything})
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
      iex> Validations.valid_items?(%Save{items: [item]})
      true

      iex> item = Data.Item.instantiate(%{id: 1, is_usable: false})
      iex> Validations.valid_items?(%Save{items: [item, :anything]})
      false

      iex> Validations.valid_items?(%Save{items: :anything})
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

      iex> Validations.valid_room_id?(%Save{room_id: 1})
      true

      iex> Validations.valid_room_id?(%Save{room_id: "overworld:1:1,1"})
      true

      iex> Validations.valid_room_id?(%Save{room_id: "overworld:111"})
      false

      iex> Validations.valid_room_id?(%Save{room_id: :anything})
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

      iex> Validations.valid_wearing?(%Save{wearing: %{}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Validations.valid_wearing?(%Save{wearing: %{chest: item}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Validations.valid_wearing?(%Save{wearing: %{eye: item}})
      false

      iex> Validations.valid_wearing?(%Save{wearing: %{finger: :anything}})
      false

      iex> Validations.valid_wearing?(%Save{wearing: :anything})
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

      iex> Validations.valid_wielding?(%Save{wielding: %{}})
      true

      iex> item = Data.Item.instantiate(%Data.Item{id: 1})
      iex> Validations.valid_wielding?(%Save{wielding: %{right: item}})
      true

      iex> Validations.valid_wielding?(%Save{wielding: %{right: :anything}})
      false

      iex> Validations.valid_wielding?(%Save{wielding: :anything})
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
