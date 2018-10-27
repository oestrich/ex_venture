defmodule Game.Format.Socials do
  @moduledoc """
  Format functions for socials
  """

  import Game.Format.Context

  alias Game.Format
  alias Game.Format.Table

  @doc """
  Format a list of socials
  """
  def socials(socials) do
    rows =
      socials
      |> Enum.map(fn social ->
        [social.name, "{command}#{social.command}{/command}"]
      end)

    rows = [["Name", "Command"] | rows]

    Table.format("List of socials", rows, [20, 20])
  end

  @doc """
  View a single social
  """
  def social(social) do
    """
    #{social.name}
    #{Format.underline(social.name)}
    Command: {command}#{social.command}{/command}

    With a target: {say}#{social.with_target}{/say}

    Without a target: {say}#{social.without_target}{/say}
    """
  end

  @doc """
  Format the social without_target text
  """
  def social_without_target(social, player) do
    context()
    |> assign(:user, Format.player_name(player))
    |> Format.template("{say}#{social.without_target}{say}")
  end

  @doc """
  Format the social with_target text
  """
  def social_with_target(social, player, target) do
    context()
    |> assign(:user, Format.player_name(player))
    |> assign(:target, Format.name(target))
    |> Format.template("{say}#{social.with_target}{say}")
  end
end
