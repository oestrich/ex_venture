defmodule Data.Script.Line do
  @moduledoc """
  Lines of the script the NPC converses with
  """

  import Data.Type

  @enforce_keys [:key, :message]
  defstruct [:key, :message, :unknown, :trigger, listeners: []]

  @type t() :: map()

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(line) when is_map(line), do: {:ok, line}
  def cast(_), do: :error

  @doc """
  Load a line from a stored map

  Cast it properly

      iex> Data.Script.Line.load(%{"key" => "start", "message" => "How are you?"})
      {:ok, %Data.Script.Line{key: "start", message: "How are you?"}}

      iex> Data.Script.Line.load(%{"key" => "start", "message" => "How are you?", "listeners" => [%{"phrase" => "good", "key" => "next"}]})
      {:ok, %Data.Script.Line{key: "start", message: "How are you?", listeners: [%{phrase: "good", key: "next"}]}}
  """
  @impl Ecto.Type
  def load(line) do
    line = for {key, val} <- line, into: %{}, do: {String.to_atom(key), val}
    line = line |> load_listeners()
    {:ok, struct(__MODULE__, line)}
  end

  defp load_listeners(event = %{listeners: listeners}) when listeners != nil do
    listeners =
      listeners
      |> Enum.map(fn (map) ->
        for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
      end)

    %{event | listeners: listeners}
  end
  defp load_listeners(event), do: event

  @impl Ecto.Type
  def dump(line) when is_map(line) do
    line = line |> Map.delete(:__struct__)
    {:ok, line}
  end
  def dump(_), do: :error

  @doc """
  Validate a line

  Basic line

      iex> Data.Script.Line.valid?(%{key: "start", message: "hi"})
      true

  Must have `key` and `message` as non-nil

      iex> Data.Script.Line.valid?(%{key: nil, message: "hi"})
      false
      iex> Data.Script.Line.valid?(%{key: "start", message: nil})
      false

  Listen is validated, must have `phrase` and `key` if present

      iex> Data.Script.Line.valid?(%{key: "start", message: "hi", listeners: []})
      true
      iex> Data.Script.Line.valid?(%{key: "start", message: "hi", listeners: [%{phrase: "hi", key: "next"}]})
      true
      iex> Data.Script.Line.valid?(%{key: "start", message: "hi", listeners: [%{phrase: "hi"}]})
      false

  For a quest

      iex> Data.Script.Line.valid?(%{key: "start", message: "Hello", trigger: "quest"})
      true

      iex> Data.Script.Line.valid?(%{key: "start"})
      false
  """
  @spec valid?(line :: t) :: boolean
  def valid?(line) do
    Enum.all?(keys(line), fn (key) -> key in [:key, :message, :listeners, :unknown, :trigger] end) &&
      Enum.all?([:key, :message], fn (key) -> key in keys(line) end) &&
      valid_listeners?(line)
  end

  def valid_listeners?(%{listeners: listeners}) do
    Enum.all?(listeners, fn (listener) ->
      keys(listener) == [:key, :phrase]
    end)
  end
  def valid_listeners?(_), do: true
end
