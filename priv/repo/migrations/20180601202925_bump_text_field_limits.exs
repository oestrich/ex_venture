defmodule Data.Repo.Migrations.BumpTextFieldLimits do
  use Ecto.Migration

  def change do
    alter table(:item_aspects) do
      modify :description, :text
    end

    alter table(:mail) do
      modify :body, :text
    end

    alter table(:npcs) do
      modify :description, :text
    end

    alter table(:rooms) do
      modify :listen, :text
      modify :notes, :text
    end

    alter table(:zones) do
      modify :description, :text
    end
  end
end
