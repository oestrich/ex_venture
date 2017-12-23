defmodule Data.Repo.Migrations.RenameItemTagsToItemAspects do
  use Ecto.Migration

  def up do
    rename table(:item_tags), to: table(:item_aspects)
    rename table(:item_taggings), to: table(:item_aspectings)

    rename table(:item_aspectings), :item_tag_id, to: :item_aspect_id

    execute "alter sequence item_taggings_id_seq rename to item_aspectings_id_seq;"
    execute "alter sequence item_tags_id_seq rename to item_aspects_id_seq;"
  end

  def down do
    execute "alter sequence item_aspects_id_seq rename to item_tags_id_seq;"
    execute "alter sequence item_aspectings_id_seq rename to item_taggings_id_seq;"

    rename table(:item_aspectings), :item_aspect_id, to: :item_tag_id

    rename table(:item_aspectings), to: table(:item_taggings)
    rename table(:item_aspects), to: table(:item_tags)
  end
end
