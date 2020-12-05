defmodule ExVenture.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: ExVenture.PubSub},
      ExVenture.Config.Cache,
      ExVenture.Repo,
      ExVenture.Application.KalevalaSupervisor,
      Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ExVenture.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule ExVenture.Application.KalevalaSupervisor do
  @moduledoc false

  use Supervisor

  def foreman_options() do
    [
      supervisor_name: Kantele.Character.Foreman.Supervisor,
      communication_module: Kantele.Communication,
      initial_controller: Kantele.Character.LoginController,
      presence_module: Kantele.Character.Presence,
      quit_view: {Kantele.Character.QuitView, "disconnected"}
    ]
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(_args) do
    telnet_config = [
      telnet: [
        port: 4646
      ],
      protocol: [
        output_processors: [
          Kalevala.Output.Tags,
          Kantele.Output.AdminTags,
          Kantele.Output.SemanticColors,
          Kalevala.Output.Tables,
          Kalevala.Output.TagColors,
          Kalevala.Output.StripTags
        ]
      ],
      foreman: foreman_options()
    ]

    children = [
      {Kantele.Config, [name: Kantele.Config]},
      {Kantele.Communication, []},
      {Kalevala.Help, [name: Kantele.Help]},
      {Kantele.World, []},
      {Kantele.Character.Presence, []},
      {Kantele.Character.Emotes, [name: Kantele.Character.Emotes]},
      {Kalevala.Character.Foreman.Supervisor, [name: Kantele.Character.Foreman.Supervisor]},
      telnet_listener(telnet_config)
    ]

    children =
      Enum.reject(children, fn child ->
        is_nil(child)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def telnet_listener(telnet_config) do
    config = Application.get_env(:ex_venture, :listener, [])

    case Keyword.get(config, :start, true) do
      true ->
        {Kalevala.Telnet.Listener, telnet_config}

      false ->
        nil
    end
  end
end
