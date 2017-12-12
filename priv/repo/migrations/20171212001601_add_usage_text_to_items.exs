defmodule Data.Repo.Migrations.AddUsageTextToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :user_text, :string, null: false, default: "You use {name} on {target}."
      add :usee_text, :string, null: false, default: "{user} uses {name} on you."
    end
  end
end
