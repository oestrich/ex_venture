defmodule Test.Networking.Socket do
  @behaviour Networking.Socket

  @doc false
  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def clear_messages() do
    start_link()
    Agent.update(__MODULE__, fn (_) -> %{} end)
  end

  @impl Networking.Socket
  def echo(socket, message) do
    start_link()
    Agent.update(__MODULE__, fn state ->
      echos = Map.get(state, :echo, [])
      Map.put(state, :echo, echos ++ [{socket, message}])
    end)
    :ok
  end

  def get_echos() do
    Agent.get(__MODULE__, fn state -> Map.get(state, :echo, []) end)
  end

  @impl Networking.Socket
  def prompt(socket, message) do
    start_link()
    Agent.update(__MODULE__, fn state ->
      prompts = Map.get(state, :prompt, [])
      Map.put(state, :prompt, prompts ++ [{socket, message}])
    end)
    :ok
  end

  def get_prompts() do
    Agent.get(__MODULE__, fn state -> Map.get(state, :prompt, []) end)
  end

  @impl Networking.Socket
  def disconnect(socket) do
    start_link()
    Agent.update(__MODULE__, fn state ->
      disconnects = Map.get(state, :disconnect, [])
      Map.put(state, :disconnect, disconnects ++ [socket])
    end)
    :ok
  end

  def get_disconnects() do
    Agent.get(__MODULE__, fn state -> Map.get(state, :disconnect, []) end)
  end

  @impl Networking.Socket
  def tcp_option(_socket, _option, _enabled), do: :ok
end
