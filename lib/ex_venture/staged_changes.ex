defmodule ExVenture.Types.Atom do
  @moduledoc """
  A database type that converts an atom to string and back
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(value) when is_atom(value) do
    {:ok, to_string(value)}
  end

  def cast(value) when is_binary(value) do
    {:ok, value}
  end

  def cast(_), do: :error

  @impl true
  def load(value) when is_binary(value) do
    {:ok, String.to_existing_atom(value)}
  end

  @impl true
  def dump(value), do: {:ok, to_string(value)}
end

defmodule ExVenture.Types.Term do
  @moduledoc """
  A database type that converts erlang terms to binary and back
  """

  use Ecto.Type

  @impl true
  def type, do: :string

  @impl true
  def cast(value) do
    {:ok, :erlang.term_to_binary(value)}
  end

  @impl true
  def load(value) do
    {:ok, :erlang.binary_to_term(value)}
  end

  @impl true
  def dump(value), do: cast(value)
end

defmodule ExVenture.StagedChanges.TempRecord do
  # This is a fake schema to allow for a `belongs_to` to exist on the
  # StagedChange below. With a `belongs_to` we can preload the struct
  # with a function and instead of loading _this_ struct, we'll load
  # the proper struct.

  @moduledoc false

  use Ecto.Schema

  schema "abstract table" do
  end
end

defmodule ExVenture.StagedChanges.StagedChange do
  @moduledoc """
  Schema for a staged change
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "abstract table: staged_changes" do
    field(:attribute, ExVenture.Types.Atom)
    field(:value, ExVenture.Types.Term)

    belongs_to(:struct, ExVenture.StagedChanges.TempRecord)

    timestamps()
  end

  def create_changeset(struct, struct_id, attribute, value) do
    struct
    |> change()
    |> put_change(:struct_id, struct_id)
    |> put_change(:attribute, attribute)
    |> put_change(:value, value)
    |> unique_constraint(:attribute,
      name: :staged_changes_struct_id_attribute_index,
      match: :suffix
    )
  end
end

defmodule ExVenture.StagedChanges do
  @moduledoc """
  Context for staging changes to structs

  Instead of saving directly to a struct any updates, save attribute/value
  pairs for the struct. They are applied directly in the web admin, but the
  game will instead load only what is committed to the struct.
  """

  import Ecto.Query

  alias ExVenture.StagedChanges.StagedChange
  alias ExVenture.Repo

  @schemas %{
    "room_staged_changes" => ExVenture.Rooms.Room,
    "zone_staged_changes" => ExVenture.Zones.Zone
  }

  @doc """
  Record changes to a struct in staged changes
  """
  def record_changes(changeset) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:changeset, fn _repo, _changes ->
        apply_action(changeset, :update)
      end)
      |> Ecto.Multi.merge(fn %{changeset: changeset} ->
        struct = changeset.data

        Enum.reduce(changeset.changes, Ecto.Multi.new(), fn {attribute, value}, multi ->
          staged_change = Ecto.build_assoc(struct, :staged_changes)
          changeset = StagedChange.create_changeset(staged_change, struct.id, attribute, value)

          Ecto.Multi.insert(multi, {:staged_change, attribute}, changeset,
            on_conflict: {:replace, [:value]},
            conflict_target: [:struct_id, :attribute]
          )
        end)
      end)
      |> Ecto.Multi.run(:struct, fn repo, %{changeset: changeset} ->
        struct = repo.preload(changeset.data, :staged_changes, force: true)
        {:ok, struct}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{struct: struct}} ->
        {:ok, struct}

      {:error, :changeset, changeset, _changes} ->
        {:error, changeset}
    end
  end

  # Wrap the changeset in a tagged tuple with `:ok` or `:error`
  # Depending on if the changeset is valid or not
  defp apply_action(changeset, :update) do
    case changeset.valid? do
      true ->
        {:ok, changeset}

      false ->
        {:error, %{changeset | action: :update}}
    end
  end

  @doc """
  Apply a struct's staged changes to the struct

  Does *not* save the changes
  """
  def apply(struct) do
    Enum.reduce(struct.staged_changes, struct, fn staged_change, struct ->
      Map.put(struct, staged_change.attribute, staged_change.value)
    end)
  end

  def apply(struct, field) do
    case Map.get(struct, field) do
      association when is_list(association) ->
        association = Enum.map(association, &apply/1)
        Map.put(struct, field, association)

      association ->
        Map.put(struct, field, apply(association))
    end
  end

  @doc """
  Commit all of the staged changes to the structs
  """
  def commit() do
    staged_change_schemas = Map.values(@schemas)

    result =
      Ecto.Multi.new()
      |> fetch_structs(staged_change_schemas)
      |> Ecto.Multi.merge(fn changes ->
        Enum.reduce(changes, Ecto.Multi.new(), fn {_table, structs}, multi ->
          commit_structs(multi, structs)
        end)
      end)
      |> Repo.transaction()

    case result do
      {:ok, _changes} ->
        :ok

      {:error, _tag, _changeset, _changes} ->
        :error
    end
  end

  defp fetch_structs(multi, schemas) do
    Enum.reduce(schemas, multi, fn schema, multi ->
      Ecto.Multi.run(multi, schema, fn repo, _changes ->
        structs =
          schema
          |> join(:inner, [s], sc in assoc(s, :staged_changes))
          |> group_by([s, sc], s.id)
          |> preload(:staged_changes)
          |> repo.all()

        {:ok, structs}
      end)
    end)
  end

  defp commit_structs(multi, structs) do
    Enum.reduce(structs, multi, fn struct, multi ->
      changeset = Ecto.Changeset.change(struct)

      changeset =
        Enum.reduce(struct.staged_changes, changeset, fn staged_change, changeset ->
          Ecto.Changeset.put_change(changeset, staged_change.attribute, staged_change.value)
        end)

      tag = struct.__meta__.source

      multi
      |> Ecto.Multi.update({tag, struct.id}, changeset)
      |> Ecto.Multi.delete_all({:delete, tag, struct.id}, Ecto.assoc(struct, :staged_changes))
    end)
  end

  @doc """
  Get all changes for all zones
  """
  def changes() do
    @schemas
    |> Map.values()
    |> Enum.map(fn schema ->
      {schema, changes(schema)}
    end)
    |> Enum.reject(fn {_schema, staged_changes} ->
      Enum.empty?(staged_changes)
    end)
    |> Enum.into(%{})
  end

  Enum.map(@schemas, fn {table, schema} ->
    def changes(unquote(schema)) do
      preloader = fn struct_ids ->
        unquote(schema)
        |> where([s], s.id in ^struct_ids)
        |> Repo.all()
      end

      {unquote(table), StagedChange}
      |> order_by([sc], asc: sc.struct_id, asc: sc.attribute)
      |> preload(struct: ^preloader)
      |> Repo.all()
    end
  end)

  @doc """
  Get a staged change by id
  """
  def get(type, id) do
    table = table_from_type(type)

    case Repo.get({table, StagedChange}, id) do
      nil ->
        {:error, :not_found}

      staged_change ->
        {:ok, staged_change}
    end
  end

  @doc """
  Delete a single staged change
  """
  def delete(staged_change) do
    Repo.delete(staged_change)
  end

  @doc """
  Clear out all staged changes for a struct
  """
  def clear(struct) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:staged_changes, Ecto.assoc(struct, :staged_changes))
      |> Repo.transaction()

    case result do
      {:ok, %{staged_changes: _staged_changes}} ->
        struct =
          struct
          |> Repo.reload()
          |> Repo.preload(:staged_changes)

        {:ok, struct}
    end
  end

  defp table_from_type("room"), do: "room_staged_changes"

  defp table_from_type("zone"), do: "zone_staged_changes"
end
