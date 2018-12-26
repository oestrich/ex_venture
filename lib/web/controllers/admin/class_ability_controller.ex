defmodule Web.Admin.ClassAbilityController do
  use Web.AdminController

  alias Web.Class
  alias Web.Ability

  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Class.new_class_ability(class)
    abilities = Ability.all()

    conn
    |> assign(:class, class)
    |> assign(:abilities, abilities)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"class_id" => class_id, "class_ability" => params}) do
    class = Class.get(class_id)

    case Class.add_ability(class, params) do
      {:ok, _class_ability} ->
        conn
        |> put_flash(:info, "Ability addeded to #{class.name}")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        abilities = Ability.all()

        conn
        |> put_flash(:error, "There was an issue adding the ability")
        |> assign(:class, class)
        |> assign(:abilities, abilities)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Class.remove_ability(id) do
      {:ok, class_ability} ->
        conn
        |> put_flash(:info, "Ability removed")
        |> redirect(to: class_path(conn, :show, class_ability.class_id))

      _ ->
        conn
        |> put_flash(:error, "There was a problem removing the ability")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
