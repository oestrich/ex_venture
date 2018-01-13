defmodule Data.Conversation do
  @moduledoc """
  In game conversations that NPCs will be listening for
  """

  import Data.Type
  import Ecto.Changeset

  @enforce_keys [:key, :message]
  defstruct [:key, :message, :unknown, listen: []]

  @type t() :: map()

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(conversation) when is_map(conversation), do: {:ok, conversation}
  def cast(_), do: :error

  @doc """
  Load an conversation from a stored map

  Cast it properly

      iex> Data.Conversation.load(%{"key" => "start", "message" => "How are you?"})
      {:ok, %Data.Conversation{key: "start", message: "How are you?"}}

      iex> Data.Conversation.load(%{"key" => "start", "message" => "How are you?", "listen" => [%{"phrase" => "good", "key" => "next"}]})
      {:ok, %Data.Conversation{key: "start", message: "How are you?", listen: [%{phrase: "good", key: "next"}]}}
  """
  @impl Ecto.Type
  def load(conversation) do
    conversation = for {key, val} <- conversation, into: %{}, do: {String.to_atom(key), val}
    conversation = conversation |> load_listen()
    {:ok, struct(__MODULE__, conversation)}
  end

  defp load_listen(event = %{listen: listen}) when listen != nil do
    listen =
      listen
      |> Enum.map(fn (map) ->
        for {key, val} <- map, into: %{}, do: {String.to_atom(key), val}
      end)

    %{event | listen: listen}
  end
  defp load_listen(event), do: event

  @impl Ecto.Type
  def dump(conversation) when is_map(conversation) do
    conversation = conversation |> Map.delete(:__struct__)
    {:ok, conversation}
  end
  def dump(_), do: :error

  @doc """
  Validate a conversation

  Basic conversation

      iex> Data.Conversation.valid?(%{key: "start", message: "hi"})
      true

  Must have `key` and `message` as non-nil

      iex> Data.Conversation.valid?(%{key: nil, message: "hi"})
      false
      iex> Data.Conversation.valid?(%{key: "start", message: nil})
      false

  Listen is validated, must have `phrase` and `key` if present

      iex> Data.Conversation.valid?(%{key: "start", message: "hi", listen: []})
      true
      iex> Data.Conversation.valid?(%{key: "start", message: "hi", listen: [%{phrase: "hi", key: "next"}]})
      true
      iex> Data.Conversation.valid?(%{key: "start", message: "hi", listen: [%{phrase: "hi"}]})
      false

      iex> Data.Conversation.valid?(%{key: "start"})
      false
  """
  @spec valid?(conversation :: t) :: boolean
  def valid?(conversation) do
    Enum.all?(keys(conversation), fn (key) -> key in [:key, :message, :listen, :unknown] end) &&
      Enum.all?([:key, :message], fn (key) -> key in keys(conversation) end) &&
      valid_listen?(conversation)
  end

  def valid_listen?(%{listen: listens}) do
    Enum.all?(listens, fn (listen) ->
      keys(listen) == [:key, :phrase]
    end)
  end
  def valid_listen?(_), do: true

  @doc """
  Validate conversations of the NPC
  """
  @spec validate_conversations(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  def validate_conversations(changeset) do
    case get_change(changeset, :conversations) do
      nil -> changeset
      conversations -> _validate_conversations(changeset, conversations)
    end
  end

  defp _validate_conversations(changeset, conversations) do
    case valid_conversations?(conversations) do
      true -> changeset
      false -> add_error(changeset, :conversations, "are invalid")
    end
  end

  @doc """
  Validate conversations of the NPC
  """
  @spec valid_conversations?([t()]) :: boolean()
  def valid_conversations?(conversations) do
    Enum.all?(conversations, &valid?/1) &&
      contains_start_key?(conversations) &&
      keys_are_all_included?(conversations)
  end

  defp contains_start_key?(conversations) do
    Enum.any?(conversations, fn (conversation) ->
      conversation.key == "start"
    end)
  end

  defp keys_are_all_included?(conversations) do
    Enum.all?(conversations, fn (conversation) ->
      Enum.all?(conversation.listen, fn (listen) ->
        Enum.any?(conversations, fn (conversation) ->
          listen.key == conversation.key
        end)
      end)
    end)
  end
end
