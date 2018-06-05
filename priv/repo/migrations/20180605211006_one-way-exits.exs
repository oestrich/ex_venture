defmodule :"Elixir.Data.Repo.Migrations.One-way-exits" do
  use Ecto.Migration

  def up do
    create table(:new_exits) do
      add :start_id, references(:rooms), null: false
      add :finish_id, references(:rooms), null: false
      add :direction, :string, null: false
      add :has_door, :boolean, default: false, null: false

      timestamps()
    end

    exits = [{:north, :south}, {:east, :west}, {:up, :down}, {:in, :out}]

    Enum.each(exits, fn {direction_a, direction_b} ->
      execute """
      insert into new_exits (start_id, finish_id, direction, has_door, inserted_at, updated_at)
        (select
          #{direction_a}_id as start_id,
          #{direction_b}_id as finish_id,
          '#{direction_b}' as direction,
          has_door,
          inserted_at,
          updated_at
        from exits
        where #{direction_a}_id IS NOT NULL and #{direction_b}_id IS NOT NULL);
      """

      execute """
      insert into new_exits (start_id, finish_id, direction, has_door, inserted_at, updated_at)
        (select
          #{direction_b}_id as start_id,
          #{direction_a}_id as finish_id,
          '#{direction_a}' as direction,
          has_door,
          inserted_at,
          updated_at
        from exits
        where #{direction_a}_id IS NOT NULL and #{direction_b}_id IS NOT NULL);
      """
    end)

    rename table(:exits), to: table(:old_exits)
    rename table(:new_exits), to: table(:exits)

    create index(:exits, [:direction, :start_id, :finish_id], unqiue: true)

    drop table(:old_exits)
  end

  def down do
    raise "Data has been lost, must press forward"
  end
end
