defmodule Web.Admin.UserController do
  use Web.AdminController

  plug(Web.Plug.FetchPage when action in [:index])

  alias Web.User

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "user", %{})
    %{page: users, pagination: pagination} = User.all(filter: filter, page: page, per: per)

    conn
    |> assign(:users, users)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    user = User.get(id)

    conn
    |> assign(:user, user)
    |> render("show.html")
  end

  def edit(conn, %{"id" => id}) do
    user = User.get(id)
    changeset = User.edit(user)

    conn
    |> assign(:user, user)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "user" => params}) do
    case User.update(id, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "#{user.name} updated!")
        |> redirect(to: user_path(conn, :show, user.id))

      {:error, changeset} ->
        user = User.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{user.name}. Please try again.")
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def watch(conn, %{"user_id" => id}) do
    user = User.get(id)

    conn
    |> assign(:user, user)
    |> render("watch.html")
  end

  def cheat(conn, %{"user_id" => id}) do
    user = User.get(id)

    conn
    |> assign(:user, user)
    |> render("cheat.html")
  end

  def cheating(conn, %{"user_id" => id, "cheat" => params}) do
    user = User.get(id)

    case User.activate_cheat(user, params) do
      {:ok, user} ->
        conn
        |> assign(:user, user)
        |> put_flash(:info, "Cheat activated")
        |> redirect(to: user_path(conn, :show, user.id))

      _ ->
        conn
        |> assign(:user, user)
        |> put_flash(:error, "There was an issue activating the cheat. Please try again.")
        |> render("cheat.html")
    end
  end

  def teleport(conn, %{"room_id" => room_id}) do
    %{user: user} = conn.assigns

    case User.teleport(user, room_id) do
      {:ok, _user} ->
        conn |> redirect(to: room_path(conn, :show, room_id))

      _ ->
        conn |> redirect(to: room_path(conn, :show, room_id))
    end
  end

  def disconnect(conn, %{"user_id" => id}) do
    with {:ok, id} <- Ecto.Type.cast(:integer, id),
         :ok <- User.disconnect(id) do
      conn |> redirect(to: user_path(conn, :show, id))
    else
      _ ->
        conn |> redirect(to: user_path(conn, :show, id))
    end
  end

  def disconnect(conn, _params) do
    case User.disconnect() do
      :ok ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end

  def reset(conn, %{"user_id" => id}) do
    case User.reset(id) do
      {:ok, user} ->
        conn |> redirect(to: user_path(conn, :show, user.id))

      {:error, _} ->
        conn |> redirect(to: user_path(conn, :show, id))
    end
  end
end
