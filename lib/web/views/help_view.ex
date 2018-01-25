defmodule Web.HelpView do
  use Web, :view

  alias Web.Color

  def command_topic_key(command) do
    command |> to_string |> String.split(".") |> List.last()
  end
end
