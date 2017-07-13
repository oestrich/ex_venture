defmodule Networking.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @server Application.get_env(:networking, :server)

  use Application

  def start(_type, _args) do

    children = [listener()]
    |> Enum.reject(fn child -> is_nil(child) end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Networking.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp listener() do
    case @server do
      true ->
        import Supervisor.Spec, warn: false
        worker(Networking.Listener, [])
      false -> nil
    end
  end
end
