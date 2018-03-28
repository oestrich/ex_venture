defmodule Web.LayoutView do
  use Web, :view

  alias Game.Config
  alias Web.Bug
  alias Web.Mail

  def tab_selected(conn, "dashboard") do
    case conn.path_info do
      ["admin"] -> "active"
      _ -> ""
    end
  end

  def tab_selected(conn, routes) when is_list(routes) do
    routes |> Enum.map(&tab_selected(conn, &1)) |> Enum.join(" ")
  end

  def tab_selected(conn, route) do
    case conn.path_info do
      ["admin", ^route] -> "active"
      ["admin", ^route, _] -> "active"
      ["admin", ^route, _, "edit"] -> "active"
      [^route] -> "active"
      [^route, _] -> "active"
      _ -> ""
    end
  end

  def user_token(%{assigns: %{user_token: token}}), do: token
  def user_token(_), do: ""

  def is_admin?(%{assigns: %{user: user}}), do: "admin" in user.flags
  def is_admin?(_), do: false

  def page_title(conn, assigns) do
    case render_existing(view_module(conn), "title", assigns) do
      nil ->
        Config.game_name()

      title ->
        "#{title} - #{Config.game_name()}"
    end
  end
end
