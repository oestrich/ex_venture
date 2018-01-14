defmodule Game.NPC.Conversation do
  @moduledoc """
  NPC conversation module, talk with players
  """

  alias Data.Conversation
  alias Data.NPC
  alias Data.User
  alias Game.Channel
  alias Game.Message
  alias Game.NPC.State

  @doc """
  Start a conversation by greeting the NPC
  """
  @spec greet(State.t(), User.t()) :: State.t()
  def greet(state = %{npc: npc}, user) do
    conversations =
      state.conversations
      |> Map.put(user.id, %{key: "start", started_at: Timex.now()})

    npc |> send_message(user, "start")

    %{state | conversations: conversations}
  end

  @doc """
  Receive a new message from a user
  """
  @spec recv(State.t(), User.t(), String.t()) :: State.t()
  def recv(state, user, message) do
    case Map.get(state.conversations, user.id, nil) do
      nil -> greet(state, user)
      %{key: key} -> continue_conversation(state, key, user, message)
    end
  end

  #
  # "Internal"
  #

  @doc """
  Continue a found conversation
  """
  @spec continue_conversation(State.t(), String.t(), User.t(), String.t()) :: State.t()
  def continue_conversation(state = %{npc: npc}, key, user, message) do
    case conversation_from_key(npc, key) do
      nil -> state
      conversation ->
        respond(state, conversation, user, message)
    end
  end

  @doc """
  Respond to a user's message
  """
  @spec respond(State.t(), Conversation.t(), User.t(), String.t()) :: String.t()
  def respond(state = %{npc: npc}, conversation, user, message) do
    case find_listener(conversation, message) do
      nil ->
        message = Message.npc_tell(npc, conversation.unknown)
        Channel.tell({:user, user}, {:npc, npc}, message)

        state
      %{key: key} ->
        conversation =
          state.conversations
          |> Map.get(user.id)
          |> Map.put(:key, key)

        npc |> send_message(user, key)

        %{state | conversations: Map.put(state.conversations, user.id, conversation)}
    end
  end

  @doc """
  Send a tell to a user
  """
  @spec send_message(NPC.t(), User.t(), String.t()) :: :ok
  def send_message(npc, user, key) do
    case conversation_from_key(npc, key) do
      nil -> :ok
      conversation ->
        message = Message.npc_tell(npc, conversation.message)
        Channel.tell({:user, user}, {:npc, npc}, message)
    end
  end

  @doc """
  Get a conversation struct by key
  """
  @spec conversation_from_key(NPC.t(), String.t()) :: Conversation.t()
  def conversation_from_key(%{conversations: nil}, _), do: nil
  def conversation_from_key(npc, key) do
    Enum.find(npc.conversations, fn (conversation) ->
      conversation.key == key
    end)
  end

  @doc """
  Find a listener on a conversation
  """
  def find_listener(conversation, message) do
    Enum.find(conversation.listeners, fn (listener) ->
      Regex.match?(~r/#{listener.phrase}/, message)
    end)
  end
end
