defmodule Data.ModelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Data.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Data.ModelCase
      import TestHelpers
      import Test.ItemsHelper
      import Test.DoorHelper
      import Test.SkillsHelper
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Data.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Data.Repo, {:shared, self()})
    end

    Agent.update(Game.Config, fn (_) -> %{} end)

    :ok
  end
end
