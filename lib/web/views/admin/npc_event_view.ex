defmodule Web.Admin.NPCEventView do
  use Web, :view

  alias Data.Events
  alias Web.Admin.SharedView

  def parse(event) do
    case Events.parse(event) do
      {:ok, event} ->
        content_tag(:pre) do
          Jason.encode!(event, pretty: true)
        end

      {:error, error} ->
        error = content_tag(:code, inspect(error))

        pre = content_tag(:pre) do
          Jason.encode!(event, pretty: true)
        end

        [
          "Error parsing the event: ", error, ". Showing the underlying data instead.",
          pre
        ]
    end
  end
end
