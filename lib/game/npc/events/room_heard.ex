defmodule Game.NPC.Events.RoomHeard do
  @moduledoc """
  Processes the `room/heard` event
  """

  alias Data.Events.RoomHeard
  alias Game.NPC.Actions
  alias Game.NPC.Events

  def process(state, sent_event) do
    state.events
    |> Events.filter(RoomHeard)
    |> Enum.each(&process_event(&1, sent_event))

    {:ok, state}
  end

  def process_event(event, sent_event) do
    {"room/heard", message} = sent_event

    with {:ok, :matches} <- check_optional_regex(event, message) do
      Actions.delay(event.actions)
    end
  end

  @doc """
  Check the optional regex against the message
  """
  def check_optional_regex(event, message) do
    options = Map.get(event, :options, %{}) || %{}

    case Map.get(options, :regex) do
      nil ->
        {:ok, :matches}

      regex ->
        {:ok, regex} = Regex.compile(regex, "i")

        case Regex.match?(regex, message.message) do
          true ->
            {:ok, :matches}

          false ->
            {:error, :no_match}
        end
    end
  end
end
