defmodule Web.ColorController do
  use Web, :controller

  alias Web.ColorCode

  def index(conn, params) do
    is_client = Map.get(params, "client", false)
    is_home = Map.get(params, "home", false)

    conn
    |> put_resp_header("content-type", "text/css")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> assign(:is_client, is_client)
    |> assign(:is_home, is_home)
    |> render("index.css", color_codes: ColorCode.all())
  end
end
