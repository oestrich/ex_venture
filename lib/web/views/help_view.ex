defmodule Web.HelpView do
  use Web, :view

  alias Data.Proficiency
  alias Game.Help.BuiltIn
  alias Web.Color

  def command_topic_key(command) do
    command |> to_string |> String.split(".") |> List.last()
  end
end
