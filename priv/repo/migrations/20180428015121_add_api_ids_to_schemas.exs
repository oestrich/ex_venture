defmodule Data.Repo.Migrations.AddApiIdsToSchemas do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :api_id, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    alter table(:skills) do
      add :api_id, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end

    alter table(:races) do
      add :api_id, :uuid, default: fragment("uuid_generate_v4()"), null: false
    end
  end
end
