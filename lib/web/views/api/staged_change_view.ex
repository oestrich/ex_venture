defmodule Web.API.StagedChangeView do
  use Web, :view

  def render("index.json", %{staged_changes: staged_changes}) do
    %{
      items: render_many(staged_changes, __MODULE__, "show.json"),
      links: []
    }
  end

  def render("show.json", %{staged_change: staged_change}) do
    %{
      attribute: staged_change.attribute,
      value: staged_change.value,
      links: []
    }
  end
end
