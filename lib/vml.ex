defmodule VML do
  @moduledoc """
  Parse VML text strings
  """

  @doc """
  Parse a string into an AST for processing
  """
  def parse(string) do
    case :vml_lexer.string(String.to_charlist(string)) do
      {:ok, tokens, _} ->
        parse_tokens(tokens)

      {:error, {_, _, reason}} ->
        {:error, :lexer, reason}
    end
  end

  @doc false
  def parse_tokens(tokens) do
    case :vml_parser.parse(tokens) do
      {:ok, ast} ->
        {:ok, pre_process(ast)}

      {:error, {_, _, reason}} ->
        {:error, :parser, reason}
    end
  end

  @doc """
  Preprocess the AST

  - Turn charlists into elixir strings
  - Collapse blocks of string nodes
  """
  def pre_process(ast) do
    ast
    |> Enum.map(&process_node/1)
    |> collapse_strings()
  end

  @doc """
  Process a single node

  Handles strings, variables, resources, and tags. Everything else
  passes through without change.
  """
  def process_node({:string, string}) do
    {:string, to_string(string)}
  end

  def process_node({:variable, string}) do
    {:variable, to_string(string)}
  end

  def process_node({:resource, resource, id}) do
    {:resource, to_string(resource), to_string(id)}
  end

  def process_node({:tag, attributes, nodes}) do
    attributes = Enum.map(attributes, fn {key, value} ->
      {key, to_string(value)}
    end)

    {:tag, attributes, pre_process(nodes)}
  end

  def process_node(node), do: node

  @doc """
  Collapse string nodes next to each other into a single node

  Recurses through the list adding the newly collapsed node into the processing stream.

      iex> VML.collapse_strings([string: "hello", string: " ", string: "world"])
      [string: "hello world"]
  """
  def collapse_strings([{:string, string1}, {:string, string2} | nodes]) do
    collapse_strings([{:string, string1 <> string2} | nodes])
  end

  def collapse_strings(nodes), do: nodes
end
