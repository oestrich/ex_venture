defmodule Web.Admin.SocialController do
  use Web.AdminController

  alias Web.Social

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "social", %{})
    %{page: socials, pagination: pagination} = Social.all(filter: filter, page: page, per: per)
    conn |> render("index.html", socials: socials, filter: filter, pagination: pagination)
  end

  def show(conn, %{"id" => id}) do
    social = Social.get(id)
    conn |> render("show.html", social: social)
  end

  def new(conn, _params) do
    changeset = Social.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"social" => params}) do
    case Social.create(params) do
      {:ok, social} ->
        conn |> redirect(to: social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    social = Social.get(id)
    changeset = Social.edit(social)
    conn |> render("edit.html", social: social, changeset: changeset)
  end

  def update(conn, %{"id" => id, "social" => params}) do
    social = Social.get(id)

    case Social.update(social, params) do
      {:ok, social} ->
        conn |> redirect(to: social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn |> render("edit.html", social: social, changeset: changeset)
    end
  end
end
