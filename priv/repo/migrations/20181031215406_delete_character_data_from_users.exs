defmodule Data.Repo.Migrations.DeleteCharacterDataFromUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      remove(:class_id)
      remove(:race_id)
      remove(:save)
    end

    alter table(:bugs) do
      remove(:user_id)
    end

    alter table(:channel_messages) do
      remove(:user_id)
    end

    alter table(:mail) do
      remove(:sender_user_id)
      remove(:receiver_user_id)
    end

    alter table(:quest_progress) do
      remove(:user_id)
    end

    alter table(:typos) do
      remove(:user_id)
    end
  end

  def down do
    raise "No cominng back - data has been deleted"
  end
end
