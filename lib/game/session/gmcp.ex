defmodule Game.Session.GMCP do
  @moduledoc """
  Helpers for pushing GMCP data
  """

  use Networking.Socket

  @doc """
  Push Character data (save stats)
  """
  @spec character(state :: map) :: :ok
  def character(%{socket: socket, user: user}) do
    socket |> @socket.push_gmcp("Character", %{name: user.name} |> Poison.encode!())
  end

  @doc """
  Push Character.Vitals data (save stats)
  """
  @spec vitals(state :: map) :: :ok
  def vitals(%{socket: socket, save: save}) do
    socket |> @socket.push_gmcp("Character.Vitals", save.stats |> Poison.encode!())
  end
end
