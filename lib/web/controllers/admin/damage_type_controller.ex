defmodule Web.Admin.DamageTypeController do
  use Web.AdminController

  alias Web.DamageType

  def index(conn, _params) do
    damage_types = DamageType.all()

    conn
    |> assign(:damage_types, damage_types)
    |> render("index.html")
  end

  def new(conn, _params) do
    changeset = DamageType.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"damage_type" => params}) do
    case DamageType.create(params) do
      {:ok, damage_type} ->
        conn
        |> put_flash(:info, "#{damage_type.key} created!")
        |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the damage type. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    damage_type = DamageType.get(id)
    changeset = DamageType.edit(damage_type)

    conn
    |> assign(:damage_type, damage_type)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "damage_type" => params}) do
    case DamageType.update(id, params) do
      {:ok, damage_type} ->
        conn
        |> put_flash(:info, "#{damage_type.key} updated!")
        |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        damage_type = DamageType.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{damage_type.key}. Please try again.")
        |> assign(:damage_type, damage_type)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
