defmodule Data.Type.Changeset do
  @moduledoc """
  A type changeset, helpful for validating a type before saving
  """

  @type t :: %__MODULE__{}

  defstruct [:data, :valid?, errors: []]

  def add_error(changeset, key, value) do
    errors = Map.get(changeset, :errors, [])
    list = Keyword.get(errors, key, [])
    list = [value | list]
    errors = Keyword.put(errors, key, list)
    %{changeset | errors: errors, valid?: false}
  end
end
