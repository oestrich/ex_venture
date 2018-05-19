defmodule Web.Admin.NPCView do
  use Web, :view
  use Game.Currency

  alias Data.Stats
  alias Game.Config
  alias Game.Skills
  alias Web.Admin.SharedView
  alias Web.Zone

  import Ecto.Changeset

  def stats(changeset) do
    case get_field(changeset, :stats) do
      nil ->
        Config.basic_stats() |> Poison.encode!(pretty: true)

      stats ->
        stats |> Stats.default() |> Poison.encode!(pretty: true)
    end
  end

  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil ->
        ""

      tags ->
        tags |> Enum.join(", ")
    end
  end

  def script(changeset) do
    case get_field(changeset, :script) do
      nil ->
        ""

      script ->
        script |> Poison.encode!(pretty: true)
    end
  end

  def custom_name?(%{name: name}) do
    name != "" && !is_nil(name)
  end

  def skills(npc) do
    Skills.skills(npc.trainable_skills)
  end

  def stat_display_name(stat) do
    stat
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
