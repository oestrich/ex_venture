defmodule Web.Plug.FetchPage do
  @moduledoc """
  Plug for fetching page parameters and adding to assigns
  """

  import Plug.Conn

  @per 20

  def init(default), do: default

  def call(conn, _opts) do
    case conn.params do
      %{"page" => page} ->
        conn
        |> assign(:page, String.to_integer(page))
        |> assign(:per, @per)

      _ ->
        conn
        |> assign(:page, 1)
        |> assign(:per, @per)
    end
  end
end
