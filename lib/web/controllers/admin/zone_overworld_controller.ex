defmodule Web.Admin.ZoneOverworldController do
  use Web.AdminController

  alias Web.Zone

  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update_map(id, params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} updated!")
        |> redirect(to: zone_path(conn, :show, zone.id))

      {:error, _changeset} ->
        zone = Zone.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{zone.name}'s map. Please try again.")
        |> redirect(to: zone_path(conn, :show, zone.id))
    end
  end
end
