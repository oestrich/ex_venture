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
      add(:seconds_online, :integer, default: 0, null: false)

      timestamps()
    end

    create index(:characters, ["lower(name)"], unique: true)

    execute """
    insert into characters (user_id, name, flags, save, class_id, race_id, inserted_at, updated_at)
    select id as user_id, name, flags, save, class_id, race_id, inserted_at, updated_at from users;
    """

    migrate_bugs()
    migrate_channel_messages()
    migrate_mail()
    migrate_quest_progress()
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

  defp migrate_mail() do
    rename table(:mail), :sender_id, to: :sender_user_id
    rename table(:mail), :receiver_id, to: :receiver_user_id

    execute "ALTER TABLE mail RENAME CONSTRAINT mail_sender_id_fkey TO mail_sender_user_id_fkey;"
    execute "ALTER TABLE mail RENAME CONSTRAINT mail_receiver_id_fkey TO mail_receiver_user_id_fkey;"

    alter table(:mail) do
      add(:sender_id, references(:characters))
      add(:receiver_id, references(:characters))
    end

    execute """
    update mail set sender_id = characters.id from characters where characters.user_id = mail.sender_user_id;
    """

    execute """
    update mail set receiver_id = characters.id from characters where characters.user_id = mail.receiver_user_id;
    """

    alter table(:mail) do
      modify(:sender_user_id, :integer, null: true)
      modify(:receiver_user_id, :integer, null: true)

      modify(:sender_id, :integer, null: false)
      modify(:receiver_id, :integer, null: false)
    end
  end

  defp migrate_quest_progress() do
    alter table(:quest_progress) do
      add(:character_id, references(:characters))
    end

    execute """
    update channel_messages set character_id = characters.id from characters where characters.user_id = channel_messages.user_id;
    """

    drop index(:quest_progress, [:user_id, :quest_id])
    create index(:quest_progress, [:character_id, :quest_id], unique: true)

    alter table(:quest_progress) do
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

    create index(:quest_progress, [:user_id, :quest_id], unique: true)
    drop index(:quest_progress, [:character_id, :quest_id])

    alter table(:quest_progress) do
      modify(:user_id, :integer, null: false)
      remove(:character_id)
    end

    alter table(:mail) do
      modify(:sender_user_id, :integer, null: false)
      modify(:receiver_user_id, :integer, null: false)
      remove(:sender_id)
      remove(:receiver_id)
    end
    rename table(:mail), :sender_user_id, to: :sender_id
    rename table(:mail), :receiver_user_id, to: :receiver_id
    execute "ALTER TABLE mail RENAME CONSTRAINT mail_sender_user_id_fkey TO mail_sender_id_fkey;"
    execute "ALTER TABLE mail RENAME CONSTRAINT mail_receiver_user_id_fkey TO mail_receiver_id_fkey;"

    alter table(:channel_messages) do
      modify(:user_id, :integer, null: false)
      remove(:character_id)
    end

    alter table(:bugs) do
      modify(:user_id, :integer, null: false)
      remove(:reporter_id)
    end
    rename table(:bugs), :user_id, to: :reporter_id
    execute "ALTER TABLE bugs RENAME CONSTRAINT bugs_user_id_fkey TO bugs_reporter_id_fkey;"

    drop table(:characters)
  end
end
