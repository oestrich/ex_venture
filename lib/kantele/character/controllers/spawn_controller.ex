defmodule Kantele.Character.SpawnController do
  use Kalevala.Character.Controller

  alias Kalevala.Brain
  alias Kantele.Character.MoveEvent
  alias Kantele.Character.NonPlayerEvents
  alias Kantele.Character.SpawnView
  alias Kantele.Character.TellEvent
  alias Kantele.CharacterChannel
  alias Kantele.Communication

  @impl true
  def init(conn) do
    character = conn.character

    conn =
      Enum.reduce(character.meta.initial_events, conn, fn initial_event, conn ->
        delay_event(conn, initial_event.delay, initial_event.topic, initial_event.data)
      end)

    conn
    |> move(:to, character.room_id, SpawnView, "spawn", %{})
    |> subscribe("rooms:#{character.room_id}", [], &MoveEvent.subscribe_error/2)
    |> register_and_subscribe_character_channel(character)
    |> event("room/look", %{})
  end

  @impl true
  def event(conn, event) do
    conn.character.brain
    |> Brain.run(conn, event)
    |> NonPlayerEvents.call(event)
  end

  @impl true
  def recv(conn, _text), do: conn

  @impl true
  def display(conn, _text), do: conn

  defp register_and_subscribe_character_channel(conn, character) do
    options = [character_id: character.id]
    :ok = Communication.register("characters:#{character.id}", CharacterChannel, options)

    options = [character: character]
    subscribe(conn, "characters:#{character.id}", options, &TellEvent.subscribe_error/2)
  end
end
