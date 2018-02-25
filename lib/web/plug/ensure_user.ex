defmodule Web.Plug.EnsureUser do
  @moduledoc """
  """

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Web.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.has_key?(conn.assigns, :user) do
      true ->
        conn

      false ->
        conn
        |> redirect(to: Routes.session_path(conn, :new))
        |> halt()
    end
  end
end
