defmodule Web.JSONHelper do
  @moduledoc """
  Helper functions for displaying stats
  """

  import Phoenix.HTML, only: [raw: 1]

  @doc """
  Encode a map as JSON
  """
  @spec encode_json(map) :: String.t()
  def encode_json(map) do
    map
    |> Poison.encode!()
    |> raw()
  end

  @doc """
  Get a field from a changeset and display as JSON
  """
  @spec json_field(Ecto.Changeset.t(), atom) :: String.t()
  def json_field(changeset, field) do
    case changeset do
      %{changes: %{^field => value}} -> parse_value(value)
      %{data: %{^field => value}} -> parse_value(value)
      %{^field => value} -> parse_value(value)
      _ -> ""
    end
  end

  defp parse_value(nil), do: ""
  defp parse_value(value) do
    case Poison.encode(value, pretty: true) do
      {:ok, value} -> value
      _ -> ""
    end
  end
end
