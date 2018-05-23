defmodule Networking.MXP do
  @moduledoc """
  Formatting for MXP

  http://www.gammon.com.au/forum/bbshowpost.php?bbsubject_id=221
  https://www.zuggsoft.com/zmud/mxp.htm
  """

  @doc """
  Maybe convert text to MXP, if the client is accepting it
  """
  @spec handle_mxp(String.t(), Keyword.t()) :: String.t()
  def handle_mxp(string, opts) do
    case Keyword.get(opts, :mxp, false) do
      true ->
        string |> convert_to_mxp()

      false ->
        string
    end
  end

  @doc """
  Strip extra attributes from command color tags. Used for going out via
  the telnet client.
  """
  @spec convert_to_mxp(String.t()) :: String.t()
  def convert_to_mxp(string) do
    string =
      string
      |> String.replace("{command}", "<send>{command}")
      |> String.replace("{/command}", "{/command}</send>")
      |> String.replace("{exit}", "<send>{exit}")
      |> String.replace("{/exit}", "{/exit}</send>")
      |> String.replace("{command click=false}", "{command}")
      |> String.replace("{exit click=false}", "{exit}")
      |> parse_send_commands()

    "\e[1z#{string}"
  end

  defp parse_send_commands(string) do
    string
    |> String.split(~r/{command send='.*'}/, include_captures: true)
    |> Enum.map(fn split ->
      case Regex.match?(~r/{command send='.*'/, split) do
        true ->
          captures = Regex.named_captures(~r/{command send='(?<send>.*)'}/, split)
          "<send href='#{captures["send"]}'>"

        false ->
          split
      end
    end)
    |> Enum.join("")
  end

  @doc """
  Strip incoming MXP from the player
  """
  @spec strip_mxp(String.t()) :: String.t()
  def strip_mxp(string) do
    string |> String.replace(~r/<[^>]*>/, "")
  end
end
