defmodule Web.Admin.QuestRelationView do
  use Web, :view

  alias Web.Quest

  def quests(quest \\ nil), do: Quest.for_select(quest)
end
