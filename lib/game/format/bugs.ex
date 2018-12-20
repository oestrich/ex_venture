defmodule Game.Format.Bugs do
  @moduledoc """
  Format functions for bugs
  """

  import Game.Format.Context

  alias Game.Format
  alias Game.Format.Table

  @doc """
  Format a list of bugs
  """
  @spec list_bugs([Bug.t()]) :: String.t()
  def list_bugs(bugs) do
    rows =
      bugs
      |> Enum.map(fn bug ->
        [to_string(bug.id), bug.title, to_string(bug.is_completed)]
      end)

    rows = [["ID", "Title", "Is Fixed?"] | rows]

    Table.format("Bugs", rows, [10, 30, 10])
  end

  @doc """
  Format a list of bugs
  """
  @spec show_bug(Bug.t()) :: String.t()
  def show_bug(bug) do
    context()
    |> assign(:title, bug.title)
    |> assign(:underline, Format.underline(bug.title))
    |> assign(:is_completed, bug.is_completed)
    |> assign(:body, bug.body)
    |> Format.template(render("show"))
  end

  defp render("show") do
    """
    [title]
    [underline]
    Fixed: [is_completed]

    [body]
    """
  end
end
