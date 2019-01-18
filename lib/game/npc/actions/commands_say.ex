defmodule Game.NPC.Actions.CommandsSay do
  @moduledoc """
  Speak to the room that the NPC is in
  """

  alias Game.Environment
  alias Game.Format
  alias Game.Message
  alias Game.NPC.Events

  @doc """
  Speak to the room
  """
  def act(state, action) do
    with {:ok, :match} <- matches_room(state, action) do
      message = select_message(action)
      message = Message.npc_say(state.npc, Format.resources(message))

      state.room_id |> Environment.say(Events.npc(state), message)
      Events.broadcast(state.npc, "room/heard", message)

      {:ok, state}
    else
      _ ->
        {:ok, state}
    end
  end

  defp matches_room(state, action) do
    case Map.get(action.options, :room_id) do
      nil ->
        {:ok, :match}

      room_id ->
        case state.room_id == room_id do
          true ->
            {:ok, :match}

          false ->
            {:error, :no_match}
        end
    end
  end

  @doc """
  Select a message to say to the room

  If `message` is present then it is used before `messages`. One of them
  must be present.

      iex> CommandsSay.select_message(%{options: %{message: "hello"}})
      "hello"

      iex> CommandsSay.select_message(%{options: %{message: "hello", messages: []}})
      "hello"

      iex> CommandsSay.select_message(%{options: %{messages: ["hello"]}})
      "hello"
  """
  def select_message(%{options: options}) do
    case Map.has_key?(options, :message) do
      true ->
        options.message

      false ->
        Enum.random(options.messages)
    end
  end
end
