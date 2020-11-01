defmodule Web.Plugs.FetchPage do
  @moduledoc """
  Plug for fetching page parameters and adding to assigns
  """

  import Plug.Conn

  @per 20

  def init(default) do
    Keyword.merge([per: @per], default)
  end

  def call(conn, opts) do
    case conn.params do
      %{"page" => page} ->
        conn
        |> assign(:page, String.to_integer(page))
        |> assign(:per, opts[:per])

      _ ->
        conn
        |> assign(:page, 1)
        |> assign(:per, opts[:per])
    end
  end
end
