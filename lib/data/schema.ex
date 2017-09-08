defmodule Data.Schema do
  @moduledoc """
  Helper for setting up Ecto
  """

  import Ecto.Changeset

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Data.Schema

      alias Data.Repo

      @type t :: %__MODULE__{}
    end
  end

  def ensure(changeset, field, default) do
    case changeset do
      %{changes: %{^field => _val}} -> changeset
      %{data: %{^field => val}} when val != nil -> changeset
      _ -> put_change(changeset, field, default)
    end
  end
end
