defmodule Game.Hint do
  @moduledoc """
  Module to help guard for hiding hints
  """

  use ExVenture.TextCompiler, "help/hint.help"
  use Networking.Socket

  import Game.Format.Context, only: [context: 0, assign: 2]

  alias Game.Format

  def hint(key, context) do
    assigns = Enum.into(context, %{})

    context()
    |> assign(assigns)
    |> Format.template(get(key))
  end

  @doc """
  Gate a hint on the player's config
  """
  @spec gate(State.t(), String.t(), map()) :: :ok
  def gate(state, key, context \\ %{}) do
    case state.save.config.hints do
      true ->
        state.socket |> @socket.echo("{hint}HINT{/hint}: #{hint(key, context)}")

      false ->
        :ok
    end
  end
end
