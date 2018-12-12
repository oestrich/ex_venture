defmodule Networking.Listener do
  @moduledoc """
  Start a new ranch listener
  """

  @port Application.get_env(:ex_venture, :networking)[:port]

  def start_link() do
    opts = %{
      socket_opts: [{:port, ExVenture.config_integer(@port)}],
      max_connections: 4096
    }

    :ranch.start_listener(__MODULE__, :ranch_tcp, opts, Networking.Protocol, [])
  end
end
