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

    migrate_bugs()
    migrate_channel_messages()
    migrate_typos()
  end

  defp migrate_bugs() do
    rename table(:bugs), :reporter_id, to: :user_id

    execute "ALTER TABLE bugs RENAME CONSTRAINT bugs_reporter_id_fkey TO bugs_user_id_fkey;"

    alter table(:bugs) do
      add(:reporter_id, references(:characters))
    end

    execute """
    update bugs set reporter_id = characters.id from characters where characters.user_id = bugs.user_id;
    """

    alter table(:bugs) do
      modify(:user_id, :integer, null: true)
      modify(:reporter_id, :integer, null: false)
    end
  end

  defp migrate_channel_messages() do
    alter table(:channel_messages) do
      add(:character_id, references(:characters))
    end

    execute """
    update channel_messages set character_id = characters.id from characters where characters.user_id = channel_messages.user_id;
    """

    alter table(:channel_messages) do
      modify(:user_id, :integer, null: true)
      modify(:character_id, :integer, null: false)
    end
  end

  defp migrate_typos() do
    rename table(:typos), :reporter_id, to: :user_id

    execute "ALTER TABLE typos RENAME CONSTRAINT typos_reporter_id_fkey TO typos_user_id_fkey;"

    alter table(:typos) do
      add(:reporter_id, references(:characters))
    end

    execute """
    update typos set reporter_id = characters.id from characters where characters.user_id = typos.user_id;
    """

    alter table(:typos) do
      modify(:user_id, :integer, null: true)
      modify(:reporter_id, :integer, null: false)
    end
  end

  def down do
    alter table(:typos) do
      modify(:user_id, :integer, null: false)
      remove(:reporter_id)
    end

    rename table(:typos), :user_id, to: :reporter_id

    execute "ALTER TABLE typos RENAME CONSTRAINT typos_user_id_fkey TO typos_reporter_id_fkey;"

    alter table(:bugs) do
      modify(:user_id, :integer, null: false)
      remove(:reporter_id)
    end

    rename table(:bugs), :user_id, to: :reporter_id

    execute "ALTER TABLE bugs RENAME CONSTRAINT bugs_user_id_fkey TO bugs_reporter_id_fkey;"

    alter table(:channel_messages) do
      modify(:user_id, :integer, null: false)
      remove(:character_id)
    end

    drop table(:characters)
  end
end
