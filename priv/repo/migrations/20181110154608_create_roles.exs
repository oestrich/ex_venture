defmodule Data.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add(:name, :text, null: false)
      add(:permissions, {:array, :string}, default: fragment("'{}'"), null: false)

      timestamps()
    end
  end
end
