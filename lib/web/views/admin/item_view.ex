defmodule Web.Admin.ItemView do
  use Web, :view

  def keywords(keywords), do: keywords |> Enum.join(", ")
end
