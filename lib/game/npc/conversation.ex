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
  alias Game.Quest

  @doc """
  Start a conversation by greeting the NPC
  """
  @spec greet(State.t(), User.t()) :: State.t()
  def greet(state = %{npc: npc}, user) do

    with true <- npc.is_quest_giver,
         {:ok, quest} <- Quest.next_available_quest_from(npc, user)
    do
      _greet(state, user, quest.conversations, %{quest_id: quest.id})
    else
      _ ->
        _greet(state, user, npc.conversations)
    end
  end

  defp _greet(state = %{npc: npc}, user, conversations, metadata \\ %{}) do
    metadata = Map.merge(metadata, %{
      key: "start",
      started_at: Timex.now(),
      conversations: conversations,
    })

    npc |> send_message(user, metadata, "start")

    state = %{state | conversations: Map.put(state.conversations, user.id, metadata)}
    update_conversation_state(state, "start", conversations, user)
  end

  @doc """
  Receive a new message from a user
  """
  @spec recv(State.t(), User.t(), String.t()) :: State.t()
  def recv(state, user, message) do
    case Map.get(state.conversations, user.id, nil) do
      nil -> greet(state, user)
      metadata -> continue_conversation(state, metadata, user, message)
    end
  end

  #
  # "Internal"
  #

  @doc """
  Continue a found conversation
  """
  @spec continue_conversation(State.t(), map(), User.t(), String.t()) :: State.t()
  def continue_conversation(state, metadata, user, message) do
    case conversation_from_key(metadata.conversations, metadata.key) do
      nil -> state
      conversation ->
        respond(state, metadata, conversation, user, message)
    end
  end

  @doc """
  Respond to a user's message
  """
  @spec respond(State.t(), map(), Conversation.t(), User.t(), String.t()) :: String.t()
  def respond(state = %{npc: npc}, metadata, conversation, user, message) do
    case find_listener(conversation, message) do
      nil ->
        message = Message.npc_tell(npc, conversation.unknown)
        Channel.tell({:user, user}, {:npc, npc}, message)

        state
      %{key: key} ->
        npc |> send_message(user, metadata, key)
        state |> update_conversation_state(key, metadata.conversations, user)
    end
  end

  @doc """
  Send a tell to a user
  """
  @spec send_message(NPC.t(), User.t(), map(), String.t()) :: :ok
  def send_message(npc, user, metadata, key) do
    case conversation_from_key(metadata.conversations, key) do
      nil -> :ok
      conversation ->
        message = Message.npc_tell(npc, conversation.message)
        Channel.tell({:user, user}, {:npc, npc}, message)
        handle_trigger(conversation, user, metadata)
    end
  end

  @doc """
  Handle the trigger for a conversation
  """
  def handle_trigger(%{trigger: nil}, _, _), do: :ok
  def handle_trigger(%{trigger: "quest"}, user, metadata) do
    Quest.start_quest(user, metadata.quest_id)
  end

  @doc """
  Get a conversation struct by key
  """
  @spec conversation_from_key([Conversation.t()], String.t()) :: Conversation.t()
  def conversation_from_key(nil, _), do: nil
  def conversation_from_key(conversations, key) do
    Enum.find(conversations, fn (conversation) ->
      conversation.key == key
    end)
  end

  @doc """
  Find a listener on a conversation
  """
  @spec find_listener(Conversation.t(), String.t()) :: map()
  def find_listener(conversation, message) do
    Enum.find(conversation.listeners, fn (listener) ->
      Regex.match?(~r/#{listener.phrase}/, message)
    end)
  end

  @doc """
  Update conversation state, possibly clearing out if the conversation ended
  """
  @spec update_conversation_state(State.t(), String.t(), [Conversation.t()], User.t()) :: State.t()
  def update_conversation_state(state, key, conversations, user) do
    conversation =
      state.conversations
      |> Map.get(user.id)
      |> Map.put(:key, key)

    case conversation_from_key(conversations, key) do
      %{listeners: []} ->
        %{state | conversations: Map.delete(state.conversations, user.id)}
      _ ->
        %{state | conversations: Map.put(state.conversations, user.id, conversation)}
    end
  end
end
