defmodule Web.Plug.PublicEnsureCharacter do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Web.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.has_key?(conn.assigns, :current_character) do
      true ->
        conn

      false ->
        uri = %URI{path: conn.request_path, query: conn.query_string}

        conn
        |> put_session(:last_path, URI.to_string(uri))
        |> redirect(to: Routes.public_character_path(conn, :new))
        |> halt()
    end
  end
end
