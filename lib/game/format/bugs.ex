defmodule Game.Format.Bugs do
  @moduledoc """
  Format functions for bugs
  """

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
    """
    #{bug.title}
    #{Format.underline(bug.title)}
    Fixed: #{bug.is_completed}

    #{bug.body}
    """
  end
end
