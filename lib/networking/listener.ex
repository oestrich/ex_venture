defmodule Networking.Listener do
  @moduledoc """
  Start a new ranch listener
  """

  @port Application.get_env(:ex_venture, :networking)[:port]

  def start_link() do
    :ranch.start_listener(
      make_ref(),
      :ranch_tcp,
      [{:port, ExVenture.config(@port)}],
      Networking.Protocol,
      []
    )
  end
end
