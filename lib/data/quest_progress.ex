defmodule Data.QuestProgress do
  @moduledoc """
  Quest Progress schema
  """

  use Data.Schema

  alias Data.Character
  alias Data.Quest

  @statuses ["active", "complete"]

  defmodule Progress do
    @moduledoc """
    Convert progress keys into integers
    """

    @behaviour Ecto.Type

    @impl Ecto.Type
    def type, do: :map

    @impl Ecto.Type
    def cast(progress) when is_map(progress), do: {:ok, progress}
    def cast(_), do: :error

    @doc """
    Load progress from the database
    """
    @impl Ecto.Type
    def load(progress) do
      progress =
        for {key, val} <- progress, into: %{}, do: {String.to_integer(key), cast_val(val)}

      {:ok, progress}
    end

    defp cast_val(map) when is_map(map) do
      for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
    end

    defp cast_val(val), do: val

    @impl Ecto.Type
    def dump(progress) when is_map(progress), do: {:ok, Map.delete(progress, :__struct__)}
    def dump(_), do: :error

    @impl true
    def embed_as(_), do: :self

    @impl true
    def equal?(term1, term2), do: term1 == term2
  end

  schema "quest_progress" do
    field(:status, :string, default: "active")
    field(:progress, Progress, default: %{})
    field(:is_tracking, :boolean, default: false)

    belongs_to(:quest, Quest)
    belongs_to(:character, Character)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:status, :progress, :is_tracking, :character_id, :quest_id])
    |> validate_required([:status, :progress, :is_tracking, :character_id, :quest_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:quest_id)
    |> unique_constraint(:quest_id, name: :quest_progress_character_id_quest_id_index)
  end
end
