defmodule Data.Repo.Migrations.AddDoorIdToExits do
  use Ecto.Migration

  def up do
    alter table(:exits) do
      add :door_id, :uuid
    end

    Enum.map([{"north", "south"}, {"east", "west"}, {"in", "out"}, {"up", "down"}], fn {direction, opposite} ->
      execute "update exits set door_id = uuid_generate_v4() where direction = '#{direction}' and has_door = 't';"
      execute """
      update exits
      set door_id = (select door_id from exits as reverse where direction = '#{direction}' and reverse.finish_room_id = exits.start_room_id)
      where direction = '#{opposite}';
      """
    end)
  end

  def down do
    alter table(:exits) do
      remove :door_id
    end
  end
end
