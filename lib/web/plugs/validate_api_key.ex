defmodule Web.Plugs.ValidateAPIKey do
  @moduledoc """
  Validate the bearer token for the API
  """

  import Plug.Conn
  import Phoenix.Controller

  alias ExVenture.APIKeys

  def init(default), do: default

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        load_token(conn, token)

      _ ->
        fail(conn)
    end
  end

  defp load_token(conn, token) do
    case APIKeys.valid?(token) do
      true ->
        conn

      false ->
        fail(conn)
    end
  end

  defp fail(conn) do
    conn
    |> put_status(401)
    |> put_view(Web.ErrorView)
    |> render("401.json")
    |> halt()
  end
end
