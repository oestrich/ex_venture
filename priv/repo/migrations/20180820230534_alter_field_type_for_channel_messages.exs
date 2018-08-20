defmodule Data.Repo.Migrations.AlterFieldTypeForChannelMessages do
  use Ecto.Migration

  def change do
    alter table(:channel_messages) do
      modify :message, :text, null: false
    end
  end
end
