defmodule Game.Message do
  @moduledoc """
  Player or NPC message, something said
  """

  defstruct [:type, :sender, :message, :formatted]

  alias Game.Format

  @type t :: %{
    type: :user | :npc,
    sender: User.t,
    message: String.t,
    formatted: String.t,
  }

  def new(user, message) do
    %__MODULE__{
      type: :user,
      sender: user,
      message: message,
      formatted: Format.say(user, message),
    }
  end

  def npc(npc, message) do
    %__MODULE__{
      type: :npc,
      sender: npc,
      message: message,
      formatted: Format.say(npc, message),
    }
  end
end
