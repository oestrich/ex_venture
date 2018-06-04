defmodule Game.Environment do
  @moduledoc """
  Look at your surroundings, whether a room or an overworld
  """

  alias Data.Room

  @type state :: Room.t()

  defmacro __using__(_opts) do
    quote do
      @environment Application.get_env(:ex_venture, :game)[:environment]
    end
  end

  @doc """
  Look around your environment
  """
  @spec look(integer() | String.t()) :: state()
  def look(id) do
    case :global.whereis_name({__MODULE__, id}) do
      :undefined ->
        {:error, :room_offline}

      pid ->
        GenServer.call(pid, :look)
    end
  end
end
