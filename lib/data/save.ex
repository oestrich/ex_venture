defmodule Data.Save do
  @moduledoc """
  User save data.
  """

  alias Data.ActionBar
  alias Data.Item
  alias Data.Save.Loader
  alias Data.Save.Validations

  @type proficiency :: map()

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
          actions: [ActionBar.action()],
          proficiencies: [proficiency()],
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
    :proficiencies,
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
  @impl Ecto.Type
  def load(save), do: Loader.load(save)

  @impl Ecto.Type
  def dump(save) when is_map(save) do
    actions =
      save.actions
      |> Enum.map(fn action ->
        Map.delete(action, :__struct__)
      end)

    save =
      save
      |> Map.put(:actions, actions)
      |> Map.delete(:__struct__)

    {:ok, save}
  end

  def dump(_), do: :error

  @impl true
  def embed_as(_), do: :self

  @impl true
  def equal?(term1, term2), do: term1 == term2

  @doc """
  Validate a save struct
  """
  @spec valid?(Save.t()) :: boolean()
  def valid?(save), do: Validations.valid?(save)
end
