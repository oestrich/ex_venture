defmodule Web.Admin.DamageTypeController do
  use Web.AdminController

  alias Web.DamageType

  def index(conn, _params) do
    damage_types = DamageType.all()
    conn |> render("index.html", damage_types: damage_types)
  end

  def new(conn, _params) do
    changeset = DamageType.new()
    conn |> render("new.html", changeset: changeset)
  end

  def create(conn, %{"damage_type" => params}) do
    case DamageType.create(params) do
      {:ok, _damage_type} ->
        conn |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        conn |> render("new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    damage_type = DamageType.get(id)
    changeset = DamageType.edit(damage_type)
    conn |> render("edit.html", damage_type: damage_type, changeset: changeset)
  end

  def update(conn, %{"id" => id, "damage_type" => params}) do
    case DamageType.update(id, params) do
      {:ok, _damage_type} ->
        conn |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        damage_type = DamageType.get(id)
        conn |> render("edit.html", damage_type: damage_type, changeset: changeset)
    end
  end
end
