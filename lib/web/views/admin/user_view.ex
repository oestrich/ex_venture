defmodule Web.Admin.UserView do
  use Web, :view

  alias Game.Format
  alias Web.Admin.SharedView

  def time(time) do
    time |> Timex.format!("%Y-%m-%d %I:%M %p", :strftime)
  end
end
