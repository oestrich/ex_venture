defmodule Web.LayoutView do
  use Web, :view

  alias Game.Config

  def tab_selected(conn, routes) when is_list(routes) do
    Enum.map(routes, &(tab_selected(conn, &1))) |> Enum.join(" ")
  end
  def tab_selected(conn, route) do
    case conn.path_info do
      ["admin", ^route] -> "active"
      ["admin", ^route, _] -> "active"
      ["admin", ^route, _, "edit"] -> "active"
      _ -> ""
    end
  end
end
