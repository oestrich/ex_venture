defmodule Web.Admin.SharedView do
  use Web, :view

  import Web.JSONHelper

  alias Data.Item

  def page_path(path, page) do
    uri = URI.parse(path)

    query =
      uri.query
      |> decode_query()
      |> Map.put(:page, page)
      |> URI.encode_query()

    %{uri | query: query}
    |> URI.to_string()
  end

  def decode_query(nil), do: %{}

  def decode_query(query) do
    URI.decode_query(query)
  end

  def previous_pagination(%{current: 1}), do: []

  def previous_pagination(%{current: current}) do
    1..(current - 1)
    |> Enum.reverse()
    |> Enum.take(3)
    |> Enum.reverse()
  end

  def more_previous?(%{current: current}), do: current > 4

  def next_pagination(%{current: page, total: page}), do: []

  def next_pagination(%{current: current, total: total}) do
    (current + 1)..total
    |> Enum.take(3)
  end

  def more_next?(%{current: current, total: total}), do: total - current >= 4

  def help_tooltip(key) do
    content_tag(
      :i,
      "",
      class: "fa fa-question-circle",
      data: [toggle: "tooltip"],
      title: Help.get(key, markdown: false)
    )
  end

  def pagination(opts) do
    render("_pagination.html", opts)
  end
end
