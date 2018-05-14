defmodule Data.Type do
  @moduledoc """
  Helper functions for types saved to the database
  """

  alias Data.Type.Changeset

  import Changeset, only: [add_error: 3]

  @type changeset :: Changeset.t()

  @doc """
  Load all non-nil keys from a struct

      iex> Data.Type.keys(%{key: 1, nil: nil})
      [:key]

      iex> Data.Type.keys(%{slot: :chest})
      [:slot]
  """
  @spec keys(struct) :: [String.t()]
  def keys(struct) do
    struct
    |> Map.delete(:__struct__)
    |> Enum.reject(fn {_key, val} -> is_nil(val) end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  @doc """
  Start data validation
  """
  @spec validate(map()) :: changeset()
  def validate(data), do: %Changeset{data: data, valid?: true}

  @doc """
  Validate the right keys are in the map
  """
  @spec validate_keys(changeset(), Keyword.t()) :: changeset()
  def validate_keys(changeset, opts) do
    required = Keyword.fetch!(opts, :required)
    one_of = Keyword.get(opts, :one_of, [])
    optional = Keyword.get(opts, :optional, [])
    keys = keys(changeset.data)

    required_missing_keys = Enum.reject(required, &Enum.member?(keys, &1))
    required_valid? = Enum.empty?(required_missing_keys)

    required_one_of_keys_count = one_of |> Enum.map(&Enum.member?(keys, &1)) |> Enum.filter(&(&1)) |> length()
    one_of_valid? = Enum.empty?(one_of) || required_one_of_keys_count == 1

    extra_keys = ((keys -- required) -- optional) -- one_of
    no_extra_keys? = Enum.empty?(extra_keys)

    case required_valid? && one_of_valid? && no_extra_keys? do
      true ->
        changeset

      false ->
        changeset
        |> maybe_add_required(required_valid?, required_missing_keys)
        |> maybe_add_one_off(one_of_valid?, one_of)
        |> maybe_add_extra_keys(no_extra_keys?, extra_keys)
    end
  end

  defp maybe_add_required(changeset, valid?, required_missing_keys) do
    case valid? do
      true ->
        changeset

      false ->
        add_error(changeset, :keys, "missing keys: #{Enum.join(required_missing_keys, ", ")}")
    end
  end

  defp maybe_add_one_off(changeset, valid?, one_of) do
    case valid? do
      true ->
        changeset

      false ->
        add_error(changeset, :keys, "requires exactly one of: #{Enum.join(one_of, ", ")}")
    end
  end

  defp maybe_add_extra_keys(changeset, valid?, extra_keys) do
    case valid? do
      true ->
        changeset

      false ->
        add_error(changeset, :keys, "there are extra keys, please remove them: #{Enum.join(extra_keys, ", ")}")
    end
  end

  @doc """
  Validate the values of the map
  """
  @spec validate_values(changeset(), ({any(), any()} -> boolean())) :: changeset()
  def validate_values(changeset, fun) do
    fields =
      changeset.data
      |> Enum.reject(fun)
      |> Enum.into(%{})
      |> Map.keys()

    case Enum.empty?(fields) do
      true ->
        changeset

      false ->
        add_error(changeset, :values, "invalid types for: #{Enum.join(fields, ", ")}")
    end
  end

  @doc """
  Ensure that a field exists in a map/struct
  """
  @spec ensure(map(), atom(), any()) :: map()
  def ensure(data, field, default) do
    case Map.has_key?(data, field) && Map.get(data, field) != nil do
      true ->
        data

      false ->
        Map.put(data, field, default)
    end
  end
end
