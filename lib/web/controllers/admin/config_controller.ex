defmodule Web.Admin.ConfigController do
  use Web.AdminController

  alias Web.Config

  def index(conn, _params) do
    conn |> render("index.html")
  end

  def edit(conn, %{"id" => name}) do
    config = Config.get(name)
    changeset = Config.edit(config)
    conn |> render("edit.html", config: config, changeset: changeset)
  end

  def update(conn, %{"id" => name, "config" => %{"value" => value}}) do
    case Config.update(name, value) do
      {:ok, _config} ->
        conn |> redirect(to: config_path(conn, :index))

      {:error, changeset} ->
        config = Config.get(name)
        conn |> render("edit.html", config: config, changeset: changeset)
    end
  end
end
