defmodule ExVenture.TextCompiler do
  @moduledoc """
  Compiler for the help text.
  """

  defmacro __using__(file) do
    help_file = Path.join(:code.priv_dir(:ex_venture), file)
    {:ok, help_text} = File.read(help_file)
    quotes = generate_gets(help_text)
    quotes = Enum.reverse([default_get() | quotes])
    [external_resource(help_file) | quotes]
  end

  defp generate_gets(help_text) do
    help_text
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.trim/1)
    |> convert_to_map()
    |> Enum.map(fn {key, val} ->
      quote do
        def get(unquote(key)) do
          unquote(val)
        end
      end
    end)
  end

  defp external_resource(help_file) do
    quote do
      @external_resource unquote(help_file)
    end
  end

  defp default_get() do
    quote do
      def get(_), do: "Not found"
    end
  end

  defp convert_to_map(lines) do
    _convert(lines, %{})
  end

  defp _convert([], map), do: map

  defp _convert([key | [val | lines]], map) do
    _convert(lines, Map.put(map, String.replace(key, ":", ""), val))
  end
end
