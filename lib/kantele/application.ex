defmodule Kantele.Application do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init(_args) do
    foreman_options = [
      supervisor_name: Kantele.Character.Foreman.Supervisor,
      communication_module: Kantele.Communication,
      initial_controller: Kantele.Character.LoginController,
      presence_module: Kantele.Character.Presence,
      quit_view: {Kantele.Character.QuitView, "disconnected"}
    ]

    telnet_config = [
      telnet: [
        port: 4444
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
      foreman: foreman_options
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
