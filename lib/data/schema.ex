defmodule Data.Schema do
  @moduledoc """
  Helper for setting up Ecto
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias Data.Repo
    end
  end
end
