defmodule Web.Admin.AbilityController do
  use Web.AdminController

  plug(:ensure_admin!)

  alias Web.Ability

  def index(conn, _params) do
    abilitys = Ability.all()

    conn
    |> assign(:abilitys, abilitys)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    with {:ok, ability} <- Ability.get(id) do
      conn
      |> assign(:ability, ability)
      |> render("show.html")
    end
  end

  def new(conn, _params) do
    changeset = Ability.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"ability" => params}) do
    case Ability.create(params) do
      {:ok, ability} ->
        conn
        |> put_flash(:info, "#{ability.name} created!")
        |> redirect(to: ability_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the ability. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    with {:ok, ability} <- Ability.get(id) do
      changeset = Ability.edit(ability)

      conn
      |> assign(:ability, ability)
      |> assign(:changeset, changeset)
      |> render("edit.html")
    end
  end

  def update(conn, %{"id" => id, "ability" => params}) do
    {:ok, ability} = Ability.get(id)

    with {:ok, ability} <- Ability.update(ability, params) do
      conn
      |> put_flash(:info, "#{ability.name} updated!")
      |> redirect(to: ability_path(conn, :index))
    else
      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue updating #{ability.name}. Please try again.")
        |> assign(:ability, ability)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
