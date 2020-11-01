defmodule Web.Plugs.ActiveTab do
  @moduledoc """
  Set the active admin side tab
  """

  import Plug.Conn

  def init(default), do: default

  def call(conn, tab: active_tab) do
    assign(conn, :active_tab, active_tab)
  end
end
