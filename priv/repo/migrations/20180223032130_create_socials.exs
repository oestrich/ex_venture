defmodule Data.Repo.Migrations.CreateSocials do
  use Ecto.Migration

  def change do
    create table(:socials) do
      add :name, :string, null: false
      add :command, :string, null: false

      add :with_target, :text, null: false
      add :without_target, :text, null: false

      timestamps()
    end
  end
end
