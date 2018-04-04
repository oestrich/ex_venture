defmodule Web.ColorCodeController do
  use Web, :controller

  alias Web.ColorCode

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/css")
    |> put_resp_header("cache-control", "max-age=86400 public")
    |> render("codes.css", color_codes: ColorCode.all())
  end
end
