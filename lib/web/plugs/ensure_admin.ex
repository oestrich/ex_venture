defmodule Web.Plugs.EnsureAdmin do
  @moduledoc """
  Verify a user is in the session
  """

  import Plug.Conn
  import Phoenix.Controller

  alias ExVenture.Users
  alias Web.Router.Helpers, as: Routes

  def init(default), do: default

  def call(conn, _opts) do
    %{current_user: user} = conn.assigns

    case Users.admin?(user) do
      true ->
        conn

      false ->
        conn
        |> put_flash(:error, "You are not an admin.")
        |> redirect(to: Routes.page_path(conn, :index))
        |> halt()
    end
  end
end
