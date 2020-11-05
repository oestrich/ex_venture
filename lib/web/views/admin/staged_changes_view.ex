defmodule Web.Admin.StagedChangesView do
  use Web, :view

  alias ExVenture.Zones.Zone

  def schema_header(Zone) do
    content_tag(:div, "Zones", class: "text-center text-lg font-bold")
  end

  def struct_link(conn, %Zone{} = zone) do
    link(zone.name, to: Routes.admin_zone_path(conn, :show, zone.id))
  end

  def delete_staged_change_link(conn, %{struct: %Zone{}} = staged_change) do
    link("Delete",
      to: Routes.admin_staged_changes_path(conn, :delete, staged_change.id, type: "zone"),
      method: :delete,
      class: "text-xs btn-secondary"
    )
  end
end
