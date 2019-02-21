defmodule Game.Events.MailReceived do
  @moduledoc """
  Event for receiving a new piece of mail
  """

  defstruct [:mail, type: "mail/recieved"]
end
