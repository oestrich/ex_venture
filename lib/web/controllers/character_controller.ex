defmodule Web.CharacterController do
  use Web, :controller

  alias ExVenture.Characters

  def create(conn, %{"character" => params}) do
    %{current_user: user} = conn.assigns

    case Characters.create(user, params) do
      {:ok, _character} ->
        conn
        |> put_flash(:info, "Character created!")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the character")
        |> redirect(to: Routes.profile_path(conn, :show))
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_user: user} = conn.assigns

    {:ok, character} = Characters.get(user, id)

    case Characters.delete(character) do
      {:ok, _character} ->
        conn
        |> put_flash(:info, "Character deleted!")
        |> redirect(to: Routes.profile_path(conn, :show))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem deleting the character")
        |> redirect(to: Routes.profile_path(conn, :show))
    end
  end
end
