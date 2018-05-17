defmodule Web.Admin.ChannelView do
  use Web, :view

  alias Web.Color

  def message_log(channel) do
    channel.messages
    |> Enum.map(fn message ->
      [
        raw(Color.format(message.formatted)),
        "\n"
      ]
    end)
  end
end
