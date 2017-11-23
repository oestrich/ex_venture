defmodule Data.Item.Instance do
  @moduledoc """
  An instance of an item
  """

  @enforce_keys [:id, :created_at]
  defstruct [:id, :created_at]
end
