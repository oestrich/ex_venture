defmodule Game.Command.Pager do
  @moduledoc """
  Paginate text to the user
  """

  use Networking.Socket

  import Game.Session, only: [prompt: 1]

  def paginate(state = %{socket: socket, pagination: %{text: text}}, opts \\ []) do
    lines = Keyword.get(opts, :lines, 20)

    {to_print, to_save} =
      text
      |> String.split("\n")
      |> Enum.split(lines)

    to_print = Enum.join(to_print, "\n")
    socket |> @socket.echo(to_print)

    case to_save |> length() do
      0 -> 
        state |> prompt()

        state
        |> Map.put(:mode, "commands")
        |> Map.delete(:pagination)
      _ -> 
        socket |> @socket.echo("Press enter to continue...")

        to_save = Enum.join(to_save, "\n")

        state
        |> Map.put(:mode, "paginate")
        |> Map.put(:pagination, %{text: to_save})
    end
  end
end
