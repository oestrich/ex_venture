defmodule Game.NPC.Conversation do
  @moduledoc """
  NPC conversation module, talk with players
  """

  alias Data.Script
  alias Data.Script.Line
  alias Data.NPC
  alias Data.User
  alias Game.Channel
  alias Game.Format
  alias Game.Message
  alias Game.NPC.State
  alias Game.Quest

  @type metadata :: map()

  @doc """
  Start a conversation by greeting the NPC
  """
  @spec greet(State.t(), User.t()) :: State.t()
  def greet(state = %{npc: npc}, user) do
    npc = %{npc | id: npc.original_id}

    with true <- npc.is_quest_giver,
         {:ok, quest} <- Quest.next_available_quest_from(npc, user) do
      _greet(state, user, quest.script, %{quest_id: quest.id})
    else
      _ ->
        _greet(state, user, npc.script)
    end
  end

  defp _greet(state = %{npc: npc}, user, script, metadata \\ %{}) do
    metadata =
      Map.merge(metadata, %{
        key: "start",
        started_at: Timex.now(),
        script: script
      })

    npc |> send_message(user, metadata, "start")

    state = %{state | conversations: Map.put(state.conversations, user.id, metadata)}
    update_conversation_state(state, "start", script, user)
  end

  @doc """
  Receive a new message from a user
  """
  @spec recv(State.t(), User.t(), String.t()) :: State.t()
  def recv(state, user, message) do
    case Map.get(state.conversations, user.id, nil) do
      nil ->
        greet(state, user)

      metadata ->
        continue_conversation(state, metadata, user, message)
    end
  end

  @doc """
  Continue a conversation

  From `trigger: line`
  """
  def continue(state, user) do
    case Map.get(state.conversations, user.id, nil) do
      nil ->
        state

      metadata ->
        handle_trigger_next(state, user, metadata)
    end
  end

  #
  # "Internal"
  #

  @doc """
  Continue a found conversation
  """
  @spec continue_conversation(State.t(), metadata(), User.t(), String.t()) :: State.t()
  def continue_conversation(state, metadata, user, message) do
    case line_from_key(metadata.script, metadata.key) do
      nil ->
        state

      conversation ->
        respond(state, metadata, conversation, user, message)
    end
  end

  @doc """
  Respond to a user's message
  """
  @spec respond(State.t(), metadata(), Line.t(), User.t(), String.t()) :: String.t()
  def respond(state = %{npc: npc}, metadata, conversation, user, message) do
    case find_listener(conversation, message) do
      nil ->
        maybe_send_unknown(npc, conversation, user)

        state

      %{key: key} ->
        npc |> send_message(user, metadata, key)
        state |> update_conversation_state(key, metadata.script, user)
    end
  end

  defp maybe_send_unknown(npc, conversation, user) do
    case conversation.unknown do
      nil ->
        :ok

      unknown ->
        message = Message.npc_tell(npc, Format.resources(unknown))
        Channel.tell({:user, user}, {:npc, npc}, message)
    end
  end

  @doc """
  Send a tell to a user
  """
  @spec send_message(NPC.t(), User.t(), metadata(), String.t()) :: :ok
  def send_message(npc, user, metadata, key) do
    case line_from_key(metadata.script, key) do
      nil ->
        :ok

      line ->
        message = Message.npc_tell(npc, Format.resources(line.message))
        Channel.tell({:user, user}, {:npc, npc}, message)
        handle_trigger(line, user, metadata)
    end
  end

  @doc """
  Handle the trigger for a line
  """
  def handle_trigger(%{trigger: nil}, _, _), do: :ok

  def handle_trigger(%{trigger: "quest"}, user, metadata) do
    Quest.start_quest(user, metadata.quest_id)
  end

  def handle_trigger(%{trigger: %{type: "line", delay: delay}}, user, _metadata) do
    delay = round(Float.ceil(delay * 1000))
    Process.send_after(self(), {:conversation, :continue, user}, delay)
  end

  @doc """
  Get a line struct by key
  """
  @spec line_from_key(Script.t(), String.t()) :: Line.t()
  def line_from_key(nil, _), do: nil

  def line_from_key(script, key) do
    Enum.find(script, fn line ->
      line.key == key
    end)
  end

  @doc """
  Find a listener on a line
  """
  @spec find_listener(Line.t(), String.t()) :: map()
  def find_listener(line, message) do
    Enum.find(line.listeners, fn listener ->
      Regex.match?(~r/#{listener.phrase}/i, message)
    end)
  end

  @doc """
  Update conversation state, possibly clearing out if the conversation ended
  """
  @spec update_conversation_state(State.t(), String.t(), Script.t(), User.t()) :: State.t()
  def update_conversation_state(state, key, script, user) do
    conversation =
      state.conversations
      |> Map.get(user.id)
      |> Map.put(:key, key)

    case line_from_key(script, key) do
      %{trigger: %{type: "line"}} ->
        %{state | conversations: Map.put(state.conversations, user.id, conversation)}

      %{listeners: []} ->
        %{state | conversations: Map.delete(state.conversations, user.id)}

      _ ->
        %{state | conversations: Map.put(state.conversations, user.id, conversation)}
    end
  end

  @doc """
  Handle the next trigger after continuing a conversation
  """
  def handle_trigger_next(state, user, metadata) do
    case line_from_key(metadata.script, metadata.key) do
      %{trigger: %{next: key}} ->
        state.npc |> send_message(user, metadata, key)
        state |> update_conversation_state(key, metadata.script, user)

      _ ->
        state
    end
  end
end
