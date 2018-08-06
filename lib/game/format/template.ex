defmodule Game.Format.Template do
  @moduledoc """
  Template a string with variables
  """

  @variable_regex ~r/\[([^\]]*)\]/

  @doc """
  Render a template with a context

  Variables are denoted with `[key]` in the template string. You can also
  include leading spaces that can be collapsed if the variable is nil or does
  not exist in the context.

  For instance:

      ~s(You say[ adverb_phrase], {say}"[message]"{/say})

  If templated with `%{message: "Hello"}` will output as:

      You say, {say}"Hello"{/say}
  """
  @spec render(String.t(), map()) :: String.t()
  def render(context, string) do
    context =
      context
      |> Map.get(:assigns, %{})
      |> Enum.map(fn {key, val} -> {to_string(key), val} end)
      |> Enum.into(%{})

    string
    |> String.split(@variable_regex, include_captures: true)
    |> Enum.map(&replace_variables(&1, context))
    |> Enum.join()
  end

  defp replace_variables(string, context) do
    case Regex.run(@variable_regex, string) do
      nil ->
        string

      [_, variable] ->
        key = String.trim(variable)
        leading_spaces = String.replace(variable, ~r/#{key}[\s]*/, "")

        case Map.get(context, key, "") do
          "" -> ""
          nil -> ""
          value -> Enum.join([leading_spaces, value])
        end
    end
  end
end
