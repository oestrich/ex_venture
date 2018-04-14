defmodule Data.Type do
  @moduledoc """
  Helper functions for types saved to the database
  """

  alias Data.Type.Changeset

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
    optional = Keyword.get(opts, :optional, [])
    keys = keys(changeset.data)

    all_required_keys? = Enum.all?(required, &Enum.member?(keys, &1))
    no_extra_keys? = Enum.empty?((keys -- required) -- optional)

    case changeset.valid? do
      true ->
        case all_required_keys? && no_extra_keys? do
          true ->
            changeset

          false ->
            %{changeset | valid?: false}
        end

      false ->
        changeset
    end
  end

  @doc """
  Validate the values of the map
  """
  @spec validate_values(changeset(), ({any(), any()} -> boolean())) :: changeset()
  def validate_values(changeset, fun) do
    case changeset.valid? do
      true ->
        case Enum.all?(changeset.data, fun) do
          true ->
            changeset

          false ->
            %{changeset | valid?: false}
        end

      false ->
        changeset
    end
  end
end
