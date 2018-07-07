defmodule Gossip.Socket do
  @moduledoc """
  The websocket connection to the Gossip network
  """

  use WebSockex

  alias Gossip.Message

  require Logger

  @url Application.get_env(:ex_venture, :gossip)[:url]

  alias Gossip.Monitor
  alias Gossip.Socket.Implementation

  def start_link() do
    state = %{
      authenticated: false,
      channels: [],
    }

    WebSockex.start_link(@url, __MODULE__, state, [name: Gossip.Socket])
  end

  def handle_connect(_conn, state) do
    Monitor.monitor()

    send(self(), {:authorize})
    {:ok, state}
  end

  def handle_frame({:text, message}, state) do
    case Implementation.receive(state, message) do
      {:ok, state} ->
        {:ok, state}

      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      :stop ->
        Logger.info("Closing the Gossip websocket", type: :gossip)
        {:close, state}

      :error ->
        {:ok, state}
    end
  end

  def handle_frame(_frame, state) do
    {:ok, state}
  end

  def handle_cast({:broadcast, channel, message}, state) do
    case Implementation.broadcast(state, channel, message) do
      {:reply, message, state} ->
        {:reply, {:text, message}, state}

      {:ok, state} ->
        {:ok, state}
    end
  end

  def handle_cast(_, state) do
    {:ok, state}
  end

  def handle_info({:authorize}, state) do
    {state, message} = Implementation.authorize(state)
    {:reply, {:text, message}, state}
  end

  defmodule Implementation do
    @moduledoc false

    require Logger

    @client_id Application.get_env(:ex_venture, :gossip)[:client_id]
    @client_secret Application.get_env(:ex_venture, :gossip)[:client_secret]
    @callback_module Game.Channel.Gossip

    def authorize(state) do
      channels = @callback_module.channels()

      message = Poison.encode!(%{
        "event" => "authenticate",
        "payload" => %{
          "client_id" => @client_id,
          "client_secret" => @client_secret,
          "user_agent" => @callback_module.user_agent(),
          "supports" => ["channels"],
          "channels" => channels,
        },
      })

      state = Map.put(state, :channels, channels)

      {state, message}
    end

    def receive(state, message) do
      with {:ok, message} <- Poison.decode(message),
           {:ok, state} <- process(state, message) do
        {:ok, state}
      else
        :stop ->
          :stop

        {:reply, message, state} ->
          {:reply, message, state}

        _ ->
          {:ok, state}
      end
    end

    def broadcast(state, channel, message) do
      case channel in state.channels do
        true ->
          message = Poison.encode!(%{
            "event" => "messages/new",
            "payload" => %{
              "channel" => channel,
              "name" => message.name,
              "message" => message.message,
            },
          })

          {:reply, message, state}

        false ->
          {:ok, state}
      end
    end

    def process(state, message = %{"event" => "authenticate"}) do
      case message do
        %{"status" => "success"} ->
          Logger.info("Authenticated against Gossip", type: :gossip)

          {:ok, Map.put(state, :authenticated, true)}

        %{"status" => "failure"} ->
          Logger.info("Failed to authenticate against Gossip", type: :gossip)

          :stop

        _ ->
          {:ok, state}
      end
    end

    def process(state, %{"event" => "heartbeat"}) do
      Logger.debug("Gossip heartbeat", type: :gossip)

      message = Poison.encode!(%{
        "event" => "heartbeat",
        "payload" => %{
          "players" => @callback_module.players(),
        },
      })

      {:reply, message, state}
    end

    def process(state, %{"event" => "messages/broadcast", "payload" => payload}) do
      message = %Message{
        channel: payload["channel"],
        game: payload["game"],
        name: payload["name"],
        message: payload["message"],
      }

      @callback_module.message_broadcast(message)

      {:ok, state}
    end

    def process(state, _), do: {:ok, state}
  end
end
