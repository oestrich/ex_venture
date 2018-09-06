defmodule Data.Repo.Migrations.SwitchToTextForOtherChannelMessages do
  use Ecto.Migration

  def change do
    alter table(:channel_messages) do
      modify :formatted, :text, null: false
    end
  end
end
