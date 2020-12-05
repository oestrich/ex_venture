defmodule Kantele.Character.SayAction do
  @moduledoc """
  Action to speak in a channel (e.g. a room)
  """

  use Kalevala.Character.Action

  @impl true
  def run(conn, params) do
    publish_message(
      conn,
      params["channel_name"],
      params["text"],
      [meta: meta(params)],
      &publish_error/2
    )
  end

  defp meta(params) do
    params
    |> Map.take(["adverb", "at_character"])
    |> Enum.map(fn {key, value} ->
      {String.to_atom(key), value}
    end)
    |> Enum.into(%{})
  end

  def publish_error(conn, _error), do: conn
end
