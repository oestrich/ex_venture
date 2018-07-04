defmodule ExVenture.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @server Application.get_env(:ex_venture, :networking)[:server]
  @report_errors Application.get_env(:ex_venture, :errors)[:report]

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children =
      [
        cluster_supervisor(),
        worker(Raft, []),
        supervisor(Data.Repo, []),
        supervisor(Web.Supervisor, []),
        supervisor(Game.Supervisor, []),
        supervisor(Gossip.Supervisor, []),
        listener()
      ]
      |> Enum.reject(&is_nil/1)

    Metrics.Setup.setup()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: ExVenture.Supervisor]

    if @report_errors do
      :ok = :error_logger.add_report_handler(Sentry.Logger)
    end

    Supervisor.start_link(children, opts)
  end

  defp cluster_supervisor() do
    if Code.ensure_compiled?(Cluster.Supervisor) do
      topologies = Application.get_env(:libcluster, :topologies)
      {Cluster.Supervisor, [topologies, [name: ExVenture.ClusterSupervisor]]}
    end
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
