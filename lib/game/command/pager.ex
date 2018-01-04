defmodule Game.Command.Pager do
  @moduledoc """
  Paginate text to the user
  """

  use Networking.Socket

  @default_lines 20

  import Game.Session.Process, only: [prompt: 1]

  @doc """
  Paginate text
  """
  def paginate(state, opts \\ []) do
    lines = Keyword.get(opts, :lines, @default_lines)
    command = Keyword.get(opts, :command, "")
    case command |> String.downcase() do
      "a" <> _ -> all(state)
      "q" <> _ -> quit(state)
      _ -> _paginate(state, lines)
    end
  end

  @doc """
  Display all text, then quit pagination.
  """
  def all(state = %{socket: socket, pagination: %{text: text}}) do
    socket |> @socket.echo(text)
    state |> quit()
  end

  @doc """
  Quit pagination. Clears the state of pagination and resets to command mode.
  """
  def quit(state) do
    state |> prompt()
    state
    |> Map.put(:mode, "commands")
    |> Map.delete(:pagination)
  end

  defp _paginate(state = %{socket: socket, pagination: %{text: text}}, lines) do
    {to_print, to_save} =
      text
      |> String.trim("\n")
      |> String.split("\n")
      |> Enum.split(lines)

    to_print = Enum.join(to_print, "\n")
    socket |> @socket.echo(to_print)

    case to_save |> length() do
      0 ->
        state |> quit()
      _ ->
        socket |> @socket.prompt("Pager: [Enter, All, Quit] > ")

        to_save = Enum.join(to_save, "\n")

        state
        |> Map.put(:mode, "paginate")
        |> Map.put(:pagination, %{text: to_save})
    end
  end
end
