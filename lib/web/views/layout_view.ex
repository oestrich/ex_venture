defmodule Web.LayoutView do
  use Web, :view

  def tab_selected(conn, route) do
    case conn.path_info do
      ["admin", ^route] -> "active"
      ["admin", ^route, _] -> "active"
      ["admin", ^route, _, "edit"] -> "active"
      _ -> ""
    end
  end
end
