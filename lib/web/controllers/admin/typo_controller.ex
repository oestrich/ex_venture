defmodule Web.Admin.TypoController do
  use Web.AdminController

  alias Web.Typo

  plug Web.Plug.FetchPage when action in [:index]

  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: typos, pagination: pagination} = Typo.all(page: page, per: per)
    conn |> render("index.html", typos: typos, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    typo = Typo.get(id)
    conn |> render("show.html", typo: typo)
  end
end
