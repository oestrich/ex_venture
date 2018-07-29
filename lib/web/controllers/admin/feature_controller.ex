defmodule Web.Admin.FeatureController do
  use Web.AdminController

  plug(Web.Plug.FetchPage when action in [:index])

  alias Web.Feature

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "feature", %{})
    %{page: features, pagination: pagination} = Feature.all(filter: filter, page: page, per: per)

    conn
    |> assign(:features, features)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    feature = Feature.get(id)

    conn
    |> assign(:feature, feature)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Feature.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"feature" => params}) do
    case Feature.create(params) do
      {:ok, feature} ->
        conn
        |> put_flash(:info, "#{feature.key} created!")
        |> redirect(to: feature_path(conn, :show, feature.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the feature. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    feature = Feature.get(id)
    changeset = Feature.edit(feature)

    conn
    |> assign(:feature, feature)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "feature" => params}) do
    case Feature.update(id, params) do
      {:ok, feature} ->
        conn
        |> put_flash(:info, "#{feature.key} updated!")
        |> redirect(to: feature_path(conn, :show, feature.id))

      {:error, changeset} ->
        feature = Feature.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{feature.key}. Please try again.")
        |> assign(:feature, feature)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Feature.delete(id) do
      {:ok, feature} ->
        conn
        |> put_flash(:info, "#{feature.key} has been deleted!")
        |> redirect(to: feature_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue deleting the feature. Please try again.")
        |> redirect(to: feature_path(conn, :index))
    end
  end
end
