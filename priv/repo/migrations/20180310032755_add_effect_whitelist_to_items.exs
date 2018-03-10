defmodule Data.Repo.Migrations.AddEffectWhitelistToItems do
  use Ecto.Migration

  def change do
    rename table(:skills), :white_list_effects, to: :whitelist_effects

    alter table(:items) do
      add :whitelist_effects, {:array, :string}, default: fragment("'{}'"), null: false
    end
  end
end
