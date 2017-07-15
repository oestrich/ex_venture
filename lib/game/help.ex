defmodule Game.Help do
  def start_link() do
    Agent.start_link(fn -> load_help() end, name: __MODULE__)
  end

  defp load_help() do
    :code.priv_dir(:ex_mud)
    |> Path.join("game/help.yml")
    |> YamlElixir.read_from_file()
  end

  def base() do
    commands = Agent.get(__MODULE__, &(&1["commands"]))
    |> Enum.map(fn ({key, %{"short" => short}}) ->
      "\t{white}#{key |> String.upcase}{/white}: #{short}\n"
    end)
    |> Enum.join("")

    "The commands you can run are:\n#{commands}"
  end

  def topic(topic) do
    case Agent.get(__MODULE__, &(Map.get(&1["commands"], topic, nil))) do
      %{"full" => full} -> full
      nil -> "Unknown topic"
    end
  end
end
