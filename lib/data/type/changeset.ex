defmodule Data.Type.Changeset do
  @moduledoc """
  A type changeset, helpful for validating a type before saving
  """

  @type t :: %__MODULE__{}

  defstruct [:data, :valid?]
end
