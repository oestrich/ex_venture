defmodule Data.Repo.Migrations.AddFlagsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :flags, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
