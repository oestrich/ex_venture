defmodule Data.Type do
  @moduledoc """
  Helper functions for types saved to the database
  """

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
end
