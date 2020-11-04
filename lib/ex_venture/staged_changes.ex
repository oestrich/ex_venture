defmodule ExVenture.Types.Atom do
  @moduledoc false

  use Ecto.Type

  def type, do: :string

  def cast(value) when is_atom(value) do
    {:ok, to_string(value)}
  end

  def cast(value) when is_binary(value) do
    {:ok, value}
  end

  def cast(_), do: :error

  def load(value) when is_binary(value) do
    {:ok, String.to_existing_atom(value)}
  end

  def dump(value), do: {:ok, to_string(value)}
end

defmodule ExVenture.Types.Term do
  @moduledoc false

  use Ecto.Type

  def type, do: :string

  def cast(value) do
    {:ok, :erlang.term_to_binary(value)}
  end

  def load(value) do
    {:ok, :erlang.binary_to_term(value)}
  end

  def dump(value), do: cast(value)
end

defmodule ExVenture.StagedChanges.StagedChange do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "abstract table: staged_changes" do
    field(:record_id, :integer)

    field(:attribute, ExVenture.Types.Atom)
    field(:value, ExVenture.Types.Term)

    timestamps()
  end

  def create_changeset(struct, record_id, attribute, value) do
    struct
    |> change()
    |> put_change(:record_id, record_id)
    |> put_change(:attribute, attribute)
    |> put_change(:value, value)
    |> unique_constraint(:attribute,
      name: :staged_changes_record_id_attribute_index,
      match: :suffix
    )
  end
end

defmodule ExVenture.StagedChanges do
  @moduledoc false

  def apply_action(changeset, :update) do
    case changeset.valid? do
      true ->
        {:ok, changeset}

      false ->
        {:error, changeset}
    end
  end

  def apply(struct) do
    Enum.reduce(struct.staged_changes, struct, fn staged_change, struct ->
      Map.put(struct, staged_change.attribute, staged_change.value)
    end)
  end
end
