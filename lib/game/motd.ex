defmodule Game.MOTD do
  @moduledoc """
  Message of the Day

  Text that appears when initially connecting to the game.
  """

  alias Game.Config

  @doc """
  Select a random MOTD to display
  """
  @spec random_motd() :: String.t()
  def random_motd() do
    Config.motd()
    |> String.split("(----)")
    |> Enum.shuffle()
    |> List.first()
    |> String.trim()
  end

  @doc """
  Select a random after sign in message to display
  """
  @spec random_asim() :: String.t()
  def random_asim() do
    Config.after_sign_in_message()
    |> String.split("(----)")
    |> Enum.shuffle()
    |> List.first()
    |> String.trim()
  end
end
