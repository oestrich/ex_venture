defmodule Game.Help do
  @moduledoc """
  Find help about a topic
  """

  @doc """
  Basic help information

  Which commands can be run.

  Example:

      iex> Regex.match?(~r(^The topics you can look up are:), Game.Help.base())
      true
  """
  def base() do
    commands = Game.Command.commands
    |> Enum.map(fn (command) ->
      key = command |> command_topic_key()
      "\t{white}#{key}{/white}: #{command.help[:short]}\n"
    end)
    |> Enum.join("")

    "The topics you can look up are:\n#{commands}"
  end

  @spec topic(topic :: String.t) :: String.t
  def topic(topic) do
    command = Game.Command.commands
    |> Enum.find(fn (command) ->
      command |> command_topic_key == topic |> String.upcase
    end)

    case command do
      nil -> "Unknown topic"
      command ->
        """
        #{command.help.full}
        Commands: #{command.commands |> Enum.join(", ")}
        Aliases: #{command.aliases |> Enum.join(", ")}
        """
    end
  end

  defp command_topic_key(command) do
    command |> to_string |> String.split(".") |> List.last |> String.upcase
  end
end
