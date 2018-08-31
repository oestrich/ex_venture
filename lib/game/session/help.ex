defmodule Game.Session.Help do
  @moduledoc """
  Help for sessions, primarily printing out help when idling
  """

  alias Game.Hint

  @idle_hint_seconds 15

  @doc """
  Called to init the state for idle hints
  """
  def init_idle(time) do
    %{last_hint: time}
  end

  @doc """
  Maybe display a hint when a user has idled and not sent any commands since login
  """
  def maybe_display_hints(state) do
    idle_time = Timex.now() |> Timex.shift(seconds: -1 * @idle_hint_seconds)

    anything? = Timex.diff(state.last_recv, state.session_started_at, :milliseconds) < 500
    idling? = Timex.after?(idle_time, state.last_recv)
    hintable? = Timex.after?(idle_time, state.idle.last_hint)

    case anything? && idling? && hintable? do
      true ->
        display_a_hint(state)

      false ->
        {:ok, state}
    end
  end

  defp display_a_hint(state = %{idle: %{key: nil}}) do
    {:ok, state}
  end

  defp display_a_hint(state) do
    key = idle_hint_key(state)

    state |> Hint.gate("session.#{key}")

    idle =
      state.idle
      |> Map.put(:key, idle_hint_next_key(key))
      |> Map.put(:last_hint, Timex.now())

    state = %{state | idle: idle}

    {:ok, state}
  end

  defp idle_hint_key(state), do: Map.get(state.idle, :key, "idle_help")

  defp idle_hint_next_key("idle_help"), do: "idle_movement"
  defp idle_hint_next_key("idle_movement"), do: "idle_communication"
  defp idle_hint_next_key(_), do: nil
end
