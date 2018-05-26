defmodule Networking.MSSP do
  @moduledoc """
  Helpers for dealing with the MSSP protocol

  http://tintin.sourceforge.net/mssp/
  """

  @mssp_var 1
  @mssp_val 2

  alias Game.Config
  alias Game.Server
  alias Game.Session

  def name() do
    name = Config.game_name()
    <<@mssp_var>> <> "NAME" <> <<@mssp_val>> <> name
  end

  def players() do
    player_count =
      Session.Registry.connected_players()
      |> length()
      |> Integer.to_string()

    <<@mssp_var>> <> "PLAYERS" <> <<@mssp_val>> <> player_count
  end

  def uptime() do
    started_at =
      Server.started_at()
      |> Timex.to_unix()
      |> Integer.to_string()

    <<@mssp_var>> <> "UPTIME" <> <<@mssp_val>> <> started_at
  end
end
