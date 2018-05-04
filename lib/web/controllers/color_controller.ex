defmodule Web.ColorController do
  use Web, :controller

  alias Web.ColorCode

  def index(conn, params) do
    is_client = Map.get(params, "client", false)

    conn
    |> put_resp_header("content-type", "text/css")
    |> put_resp_header("cache-control", "max-age=86400 public")
    |> assign(:is_client, is_client)
    |> render("index.css", color_codes: ColorCode.all())
  end
end
