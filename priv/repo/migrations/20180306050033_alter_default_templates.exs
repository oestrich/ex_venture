defmodule Data.Repo.Migrations.AlterDefaultTemplates do
  use Ecto.Migration

  def up do
    alter table(:items) do
      modify :user_text, :string, null: false, default: "You use [name] on [target]."
      modify :usee_text, :string, null: false, default: "[user] uses [name] on you."
    end

    alter table(:npcs) do
      modify :description, :string, default: "[status_line]", null: false
      modify :status_line, :string, default: "[name] is here.", null: false
    end
  end

  def down do
    alter table(:npcs) do
      modify :description, :string, default: "{status_line}", null: false
      modify :status_line, :string, default: "{name} is here.", null: false
    end

    alter table(:items) do
      modify :user_text, :string, null: false, default: "You use {name} on {target}."
      modify :usee_text, :string, null: false, default: "{user} uses {name} on you."
    end
  end
end
