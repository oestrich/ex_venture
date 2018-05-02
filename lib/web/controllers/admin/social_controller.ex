defmodule Web.Admin.SocialController do
  use Web.AdminController

  alias Web.Social

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "social", %{})
    %{page: socials, pagination: pagination} = Social.all(filter: filter, page: page, per: per)

    conn
    |> assign(:socials, socials)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    social = Social.get(id)

    conn
    |> assign(:social, social)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Social.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"social" => params}) do
    case Social.create(params) do
      {:ok, social} ->
        conn
        |> put_flash(:info, "Created #{social.name}!")
        |> redirect(to: social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the social. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    social = Social.get(id)
    changeset = Social.edit(social)

    conn
    |> assign(:social, social)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "social" => params}) do
    social = Social.get(id)

    case Social.update(social, params) do
      {:ok, social} ->
        conn
        |> put_flash(:info, "Updated #{social.name}!")
        |> redirect(to: social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating #{social.name}. Please try again.")
        |> assign(:social, social)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
