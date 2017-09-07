defmodule Web.JSONHelper do
  @moduledoc """
  Helper functions for displaying stats
  """

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
