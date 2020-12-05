defmodule Kantele.Character.ReloadCommand do
  @moduledoc """
  WARNING

  Use this command only for development purposes!

  It will hard refresh all game state
  """

  use Kalevala.Character.Command

  alias Kantele.Character.ReloadView

  def recompile(conn, _params) do
    if Code.ensure_loaded?(Mix) do
      IEx.Helpers.recompile()
    end

    render(conn, ReloadView, "recompiled")
  end

  def reload(conn, _params) do
    if Code.ensure_loaded?(Mix) do
      IEx.Helpers.recompile()
    end

    Kantele.World.Kickoff.reload()

    render(conn, ReloadView, "reloaded")
  end
end
