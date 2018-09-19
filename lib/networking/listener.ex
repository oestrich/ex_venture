defmodule Networking.Listener do
  @moduledoc """
  Start a new ranch listener
  """

  @port Application.get_env(:ex_venture, :networking)[:port]

  def start_link() do
    :ranch.start_listener(
      __MODULE__,
      :ranch_tcp,
      [{:port, ExVenture.config_integer(@port)}, {:max_connections, 4096}],
      Networking.Protocol,
      []
    )
  end
end
