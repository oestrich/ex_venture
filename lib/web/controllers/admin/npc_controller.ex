defmodule Web.Admin.NPCController do
  use Web.AdminController

  alias Web.NPC

  plug(Web.Plug.FetchPage when action in [:index])

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "npc", %{})
    %{page: npcs, pagination: pagination} = NPC.all(filter: filter, page: page, per: per)

    conn
    |> assign(:npcs, npcs)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    npc = NPC.get(id)

    conn
    |> assign(:npc, npc)
    |> render("show.html")
  end

  def new(conn, params) do
    changeset =
      case params do
        %{"clone_id" => id} ->
          NPC.clone(id)

        _ ->
          NPC.new()
      end

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"npc" => params}) do
    case NPC.create(params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Created #{npc.name}!")
        |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the NPC. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    npc = NPC.get(id)
    changeset = NPC.edit(npc)

    conn
    |> assign(:npc, npc)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Updated #{npc.name}!")
        |> redirect(to: npc_path(conn, :show, npc.id))

      {:error, changeset} ->
        npc = NPC.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{npc.name}. Please try again.")
        |> assign(:npc, npc)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
