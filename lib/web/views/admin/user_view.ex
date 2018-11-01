defmodule Web.Admin.UserView do
  use Web, :view

  import Web.TimeView

  alias Web.Admin.SharedView
  alias Web.User

  def command_name(command) do
    command
    |> String.split(".")
    |> List.last()
  end

  def checked_flag?(user, flag) do
    flag in user.flags
  end
end
