defmodule Web.SharedView do
  use Web, :view

  alias Web.Admin.SharedView

  @doc """
  Generate pagination links for an API resource
  """
  def page_links(pagination, url) do
    cond do
      pagination.empty? ->
        []

      pagination.total == 1 ->
        []

      pagination.current == 1 ->
        [%{rel: "next", href: SharedView.page_path(url, pagination.current + 1)}]

      pagination.current == pagination.total ->
        [%{rel: "prev", href: SharedView.page_path(url, pagination.current - 1)}]

      true ->
        [
          %{rel: "next", href: SharedView.page_path(url, pagination.current + 1)},
          %{rel: "prev", href: SharedView.page_path(url, pagination.current - 1)}
        ]
    end
  end
end
