defmodule Game.Authentication do
  @moduledoc """
  Find and validate a player
  """
  import Ecto.Query

  alias Data.Character
  alias Data.Repo
  alias Data.Skill
  alias Data.Stats
  alias Data.User
  alias Game.Account

  @doc """
  Find a player by an id and preload properly
  """
  @spec find_character(integer()) :: nil | User.t()
  def find_character(character_id) do
    Character
    |> where([c], c.id == ^character_id)
    |> preloads()
    |> Repo.one()
    |> set_defaults()
    |> Account.migrate()
  end

  defp preloads(query) do
    query
    |> preload([:race, :user])
    |> preload(class: [skills: ^from(s in Skill, order_by: [s.level, s.id])])
  end

  @doc """
  Ensure that the player's stats include all required fields. Uses `Data.Stats.default/1`.
  """
  @spec set_defaults(nil | User.t()) :: nil | User.t()
  def set_defaults(player)

  def set_defaults(nil), do: nil

  def set_defaults(player) do
    stats = player.save.stats |> Stats.default()
    %{player | save: %{player.save | stats: stats}}
  end
end
