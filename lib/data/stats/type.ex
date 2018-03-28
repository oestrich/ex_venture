defmodule Data.Stats.Type do
  @moduledoc """
  Ecto type for a database column matching a stat type
  """

  alias Data.Stats

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(stat) do
    fields = Stats.basic_fields() |> Enum.map(&to_string/1)
    case stat in fields do
      true ->
        {:ok, String.to_atom(stat)}

      false ->
        :error
    end
  end

  @impl Ecto.Type
  def load(stat) do
    {:ok, String.to_atom(stat)}
  end

  @impl Ecto.Type
  def dump(stat) when is_atom(stat) do
    {:ok, to_string(stat)}
  end
  def dump(_), do: :error
end
