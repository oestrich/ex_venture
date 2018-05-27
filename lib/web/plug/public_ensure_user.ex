defmodule Web.Plug.PublicEnsureUser do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Web.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.has_key?(conn.assigns, :user) do
      true ->
        conn

      false ->
        uri = %URI{path: conn.request_path, query: conn.query_string}

        conn
        |> put_session(:last_path, URI.to_string(uri))
        |> redirect(to: Routes.public_session_path(conn, :new))
        |> halt()
    end
  end
end
