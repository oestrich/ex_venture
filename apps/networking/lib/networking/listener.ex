defmodule Networking.Listener do
  def start_link() do
    :ranch.start_listener(make_ref(), :ranch_tcp, [{:port, 5555}], Networking.Protocol, [])
  end
end
