defmodule Web.Views.Help do
  @moduledoc """
  Stand in class for the help text. This will automatically run the help text through
  `Earmark` in order to have `code` ticks work.
  """

  import Phoenix.HTML, only: [raw: 1]

  def get(arg, [markdown: false]) do
    arg
    |> Web.Help.get()
  end

  def get(arg) do
    arg
    |> Web.Help.get()
    |> Earmark.as_html!()
    |> raw()
  end
end
