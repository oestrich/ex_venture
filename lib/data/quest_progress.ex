defmodule Data.QuestProgress do
  @moduledoc """
  Quest Progress schema
  """

  use Data.Schema

  alias Data.Quest
  alias Data.User

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
    def load(event) do
      event = for {key, val} <- event, into: %{}, do: {String.to_integer(key), val}
      {:ok, event}
    end

    @impl Ecto.Type
    def dump(progress) when is_map(progress), do: {:ok, Map.delete(progress, :__struct__)}
    def dump(_), do: :error
  end

  schema "quest_progress" do
    field(:status, :string, default: "active")
    field(:progress, Progress, default: %{})
    field(:is_tracking, :boolean, default: false)

    belongs_to(:quest, Quest)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:status, :progress, :is_tracking, :user_id, :quest_id])
    |> validate_required([:status, :progress, :is_tracking, :user_id, :quest_id])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:quest_id)
    |> unique_constraint(:quest_id, name: :quest_progress_user_id_quest_id_index)
  end
end
