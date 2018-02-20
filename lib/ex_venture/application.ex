defmodule ExVenture.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @server Application.get_env(:ex_venture, :networking)[:server]

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children =
      [
        supervisor(Data.Repo, []),
        supervisor(Web.Supervisor, []),
        supervisor(Game.Registries, []),
        supervisor(Game.Supervisor, []),
        listener()
      ]
      |> Enum.reject(&is_nil/1)

    Metrics.Setup.setup()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: ExVenture.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp listener() do
    case @server do
      true ->
        import Supervisor.Spec, warn: false
        worker(Networking.Listener, [])

      false ->
        nil
    end
  end
end
