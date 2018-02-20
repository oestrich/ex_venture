defmodule Networking.SSLListener do
  @moduledoc """
  Start a new ranch listener
  """

  @port Application.get_env(:ex_venture, :networking)[:ssl_port]
  @certfile Application.get_env(:ex_venture, :networking)[:certfile]
  @keyfile Application.get_env(:ex_venture, :networking)[:keyfile]

  def start_link() do
    :ranch.start_listener(
      make_ref(),
      :ranch_ssl,
      [
        {:port, ExVenture.config(@port)},
        {:certfile, ExVenture.config(@certfile)},
        {:keyfile, ExVenture.config(@keyfile)}
      ],
      Networking.Protocol,
      []
    )
  end
end
