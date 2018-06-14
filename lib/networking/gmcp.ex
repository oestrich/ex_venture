defmodule Networking.GMCP do
  @moduledoc """
  GMCP utilities
  """

  alias Networking.Procotol

  @type message :: String.t()

  @doc """
  Check if the message is allowed for the telnet connection

  Message format is: Module[.SubModule].Message
  """
  @spec message_allowed?(Procotol.state(), message()) :: boolean()
  def message_allowed?(state, message) do
    [_message | module] = Enum.reverse(String.split(message, "."))
    module = Enum.join(module, ".")
    module in state.gmcp_supports || module == "Core"
  end
end
