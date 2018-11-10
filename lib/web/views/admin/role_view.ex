defmodule Web.Admin.RoleView do
  use Web, :view

  alias Web.Role

  def permission_field(changeset, resource) do
    permissions =
      case Ecto.Changeset.get_field(changeset, :permissions) do
        permissions when is_list(permissions) ->
          permissions

        _ ->
          []
      end

    content_tag(:select, id: "role-permission-#{resource}", name: "role[permissions][]", class: "form-control") do
      [
        content_tag(:option, "None", value: ""),
        Enum.map(Role.accesses(), fn access ->
          permission = "#{resource}/#{access}"

          opts = [value: permission]
          opts = maybe_select(opts, permissions, permission)
          content_tag(:option, String.capitalize(access), opts)
        end)
      ]
    end
  end

  defp maybe_select(opts, permissions, permission) do
    case permission in permissions do
      true ->
        [{:selected, "selected"} | opts]

      false ->
        opts
    end
  end
end
