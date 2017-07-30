defmodule Networking.Listener do
  @moduledoc """
  Start a new ranch listener
  """

  def start_link() do
    :ranch.start_listener(make_ref(), :ranch_tcp, [{:port, 5555}], Networking.Protocol, [])
  end
end
