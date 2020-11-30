defmodule Kantele.Character.CommandController do
  use Kalevala.Character.Controller

  require Logger

  alias Kalevala.Output.Tags
  alias Kantele.Character.Commands
  alias Kantele.Character.CommandView
  alias Kantele.Character.Events
  alias Kantele.Character.IncomingEvents

  @impl true
  def init(conn) do
    prompt(conn, CommandView, "prompt", %{})
  end

  @impl true
  def recv(conn, ""), do: conn

  def recv(conn, data) do
    Logger.info("Received - #{inspect(data)}")

    data = Tags.escape(data)

    case Commands.call(conn, data) do
      {:error, :unknown} ->
        conn
        |> render(CommandView, "unknown", %{})
        |> prompt(CommandView, "prompt", %{})

      conn ->
        case Map.get(conn.assigns, :prompt, true) do
          true ->
            prompt(conn, CommandView, "prompt", %{})

          false ->
            conn
        end
    end
  end

  @impl true
  def recv_event(conn, event) do
    Logger.debug("Received event from client - #{inspect(event)}")

    IncomingEvents.call(conn, event)
  end

  @impl true
  def event(conn, event), do: Events.call(conn, event)

  @impl true
  def display(conn, event) do
    any_text? =
      Enum.any?(event.output, fn output ->
        match?(%Kalevala.Character.Conn.Text{}, output) ||
          match?(%Kalevala.Character.Conn.EventText{}, output)
      end)

    case any_text? do
      true ->
        conn
        |> super(event)
        |> prompt(CommandView, "prompt", %{})

      false ->
        super(conn, event)
    end
  end
end
