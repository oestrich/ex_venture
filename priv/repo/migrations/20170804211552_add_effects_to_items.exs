defmodule Data.Repo.Migrations.AddEffectsToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :effects, {:array, :map}, default: fragment(~s('{}')), null: false
    end
  end
end
