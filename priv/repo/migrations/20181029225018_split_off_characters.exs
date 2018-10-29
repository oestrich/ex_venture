defmodule Data.Repo.Migrations.SplitOffCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add(:user_id, references(:users), null: false)
      add(:name, :string, null: false)
      add(:flags, {:array, :string}, default: fragment("'{}'"), null: false)
      add(:save, :jsonb, null: false)
      add(:class_id, references(:classes), null: false)
      add(:race_id, references(:races), null: false)

      timestamps()
    end

    create index(:characters, ["lower(name)"], unique: true)

    execute """
    insert into characters (user_id, name, flags, save, class_id, race_id, inserted_at, updated_at)
    select id as user_id, name, flags, save, class_id, race_id, inserted_at, updated_at from users;
    """
  end

  def down do
    drop table(:characters)
  end
end
