defmodule Web.AdminController do
  alias Data.User

  import Plug.Conn
  import Phoenix.Controller

  alias Web.Router.Helpers, as: Routes

  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      import Web.AdminController, only: [ensure_user!: 2, ensure_at_least_builder!: 2, ensure_admin!: 2]

      plug(:put_layout, "admin.html")
      plug(Web.Plug.LoadUser)
      plug(Web.Plug.LoadCharacter)
      plug(:ensure_user!)
      plug(:ensure_at_least_builder!)
    end
  end

  def ensure_user!(conn, _opts) do
    case Map.has_key?(conn.assigns, :current_user) do
      true ->
        conn

      false ->
        conn |> redirect(to: Routes.session_path(conn, :new)) |> halt()
    end
  end

  def ensure_at_least_builder!(conn, _opts) do
    %{current_user: user} = conn.assigns

    case User.is_admin?(user) || User.is_builder?(user) do
      true ->
        conn

      false ->
        conn
        |> redirect(to: Routes.public_page_path(conn, :index))
        |> halt()
    end
  end

  def ensure_admin!(conn, _opts) do
    %{current_user: user} = conn.assigns

    case User.is_admin?(user) do
      true ->
        conn

      false ->
        conn
        |> redirect(to: Routes.dashboard_path(conn, :index))
        |> halt()
    end
  end
end
