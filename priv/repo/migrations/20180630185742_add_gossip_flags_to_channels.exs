defmodule Data.Repo.Migrations.AddGossipFlagsToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :is_gossip_connected, :boolean, default: false, null: false
      add :gossip_channel, :string
    end
  end
end
