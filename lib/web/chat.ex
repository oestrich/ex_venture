defmodule Web.Chat do
  @moduledoc """
  Helpers for the web based chat
  """

  def channels(user) do
    user.save.channels
  end
end
