defmodule Kantele.Character.DelayEventAction do
  @moduledoc """
  Delay an event
  """

  use Kalevala.Character.Action

  @impl true
  def run(conn, params) do
    minimum_delay = Map.get(params, "minimum_delay", 0)
    random_delay = Map.get(params, "random_delay", 0)
    delay = minimum_delay + Enum.random(0..random_delay)

    data =
      params
      |> Map.get("data", %{})
      |> Enum.into(%{}, fn {key, value} ->
        {String.to_atom(key), value}
      end)

    delay_event(conn, delay, params["topic"], data)
  end
end
